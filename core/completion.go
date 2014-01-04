package core

//#include "completion.h"
//#cgo LDFLAGS: -llua
import "C"

import (
	"../lgo"
	"strings"
	"time"
	"unsafe"
)

func setup_completion(lua *lgo.Lua) {
	C.setup_completion(lua.State)
}

// provider

type Providers struct {
	Providers map[string]ProvideFunc
}

type ProvideFunc func(input string, info map[string]interface{}) [][]string

var provider_holder = make([]*Providers, 0)

func new_providers() *Providers {
	providers := &Providers{
		Providers: make(map[string]ProvideFunc),
	}
	provider_holder = append(provider_holder, providers) // to avoid gc
	return providers
}

// get candidates

func get_candidates(input string, providersp unsafe.Pointer, info map[string]interface{}) [][]string {
	texts := make(map[string]bool)
	providers := make(map[string][]string)
	descriptions := make(map[string][]string)
	distances := make(map[string]int)

	// from GlobalVocabulary
	GlobalVocabulary.Lock()
	l := len(GlobalVocabulary.Texts)
	GlobalVocabulary.Unlock()
	var word *Word
	for i := 0; i < l; i++ {
		GlobalVocabulary.Lock()
		word = GlobalVocabulary.Words[GlobalVocabulary.Texts[i]]
		GlobalVocabulary.Unlock()
		if match, distance := fuzzyMatch(word.Text, input); match {
			texts[word.Text] = true
			distances[word.Text] = distance
			providers[word.Text] = []string{}
		}
	}

	// extra providers
	for source, provider := range (*Providers)(providersp).Providers {
		for _, pair := range provider(input, info) {
			text := pair[0]
			if input != "" {
				if match, _ := fuzzyMatch(text, input); !match {
					continue
				}
			}
			GlobalVocabulary.Add(text)
			texts[text] = true
			providers[text] = append(providers[text], source)
			descriptions[text] = append(descriptions[text], "<"+source+"> "+pair[1])
			distances[text] = 0
		}
	}
	go func() {
		time.Sleep(time.Millisecond * 300)
		C.emit()
	}()

	// sort
	max_results := 8
	result := make([][]string, 0, max_results)
	var left, right *Word
	for text := range texts {
		pos := 0
		for _, target := range result { // compare
			GlobalVocabulary.Lock()
			left = GlobalVocabulary.Words[text]
			right = GlobalVocabulary.Words[target[0]]
			GlobalVocabulary.Unlock()
			if compare(input, left, right, distances[text], distances[target[0]], providers) { // win
				break
			} else {
				pos++
			}
		}
		if pos >= max_results {
			continue
		} else if pos == len(result) {
			result = append(result, []string{text, strings.Join(descriptions[text], "\n")})
		} else {
			if len(result) < max_results {
				result = append(result, nil)
			}
			for i := len(result) - 1; i >= pos+1; i-- {
				result[i] = result[i-1]
			}
			result[pos] = []string{text, strings.Join(descriptions[text], "\n")}
		}
	}

	return result
}

func compare(input string, left, right *Word, ldistance, rdistance int, providers map[string][]string) bool {
	if len(providers[left.Text]) > len(providers[right.Text]) {
		return true
	}
	if !(left.LatestSelected.Equal(right.LatestSelected)) {
		return left.LatestSelected.After(right.LatestSelected)
	}
	return ldistance <= rdistance
}

func fuzzyMatch(text, input string) (bool, int) {
	distance := 0
	if input == text {
		return false, distance
	}
	var i, j int
	ltext := len(text)
	linput := len(input)
	text = strings.ToLower(text)
	input = strings.ToLower(input)
	for i < ltext && j < linput {
		if text[i] == input[j] {
			i++
			j++
		} else {
			i++
			distance++
		}
	}
	return j == linput, distance
}

// word statistics

func on_word_completed(info map[string]string) {
	GlobalVocabulary.Lock()
	word, ok := GlobalVocabulary.Words[info["text"]]
	if !ok {
		p("%s is not in GlobalVocabulary", info["text"])
		return
	}
	p("%v\n", word)
	word.TotalFrequency++
	word.FrequencyByInput[info["input"]]++
	word.FrequencyByFiletype[info["file_type"]]++
	word.FrequencyByFilename[info["file_name"]]++
	word.LatestSelected = time.Now()
	GlobalVocabulary.Unlock()
}
