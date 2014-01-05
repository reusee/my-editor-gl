package core

//#include <string.h>
//#include "completion.h"
//#include <lua.h>
//#include <gtk/gtk.h>
import "C"

import (
	"github.com/reusee/lgo"
	"reflect"
	"strings"
	"sync"
	"time"
	"unsafe"
)

type Result struct {
	serial     int
	candidates [][]string
}

var Lua *lgo.Lua
var results = make(chan Result, 1024)
var callbackName = C.CString("async_update_candidates")

var fun = func() {
	res := <-results
	C.lua_rawgeti(Lua.State, C.LUA_REGISTRYINDEX, C.LUA_RIDX_GLOBALS)
	C.lua_getfield(Lua.State, C.int(-1), callbackName)
	Lua.PushGoValue(reflect.ValueOf(res.serial))
	Lua.PushGoValue(reflect.ValueOf(res.candidates))
	C.lua_callk(Lua.State, C.int(2), C.int(0), C.int(0), nil)
}

func setup_completion(lua *lgo.Lua) {
	Lua = lua
	C.setup_completion(unsafe.Pointer(&fun))
}

// provider

type Providers struct {
	Providers map[string]ProvideFunc
}

type ProvideFunc func(input string, content []byte, info map[string]interface{}) [][]string

var provider_holder = make([]*Providers, 0)

func new_providers() *Providers {
	providers := &Providers{
		Providers: make(map[string]ProvideFunc),
	}
	provider_holder = append(provider_holder, providers) // to avoid gc
	return providers
}

// get candidates

func get_candidates(serial int, input string, providersp unsafe.Pointer, info map[string]interface{}) [][]string {
	texts := make(map[string]bool)
	providers := make(map[string][]string)
	descriptions := make(map[string][]string)
	distances := make(map[string]int)
	var lock sync.Mutex

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

	// get buffer content
	buffer := (*C.GtkTextBuffer)(info["buffer"].(unsafe.Pointer))
	var start_iter, end_iter C.GtkTextIter
	C.gtk_text_buffer_get_start_iter(buffer, &start_iter)
	C.gtk_text_buffer_get_end_iter(buffer, &end_iter)
	cContent := C.gtk_text_buffer_get_text(buffer, &start_iter, &end_iter, C.gtk_false())
	content := C.GoBytes(unsafe.Pointer(cContent), C.int(C.strlen((*C.char)(cContent))))

	result := sort(input, texts, distances, providers, descriptions)

	// extra providers
	for source, provider := range (*Providers)(providersp).Providers {
		go func() {
			lock.Lock()
			for _, pair := range provider(input, content, info) {
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
			result := sort(input, texts, distances, providers, descriptions)
			lock.Unlock()
			C.emit()
			results <- Result{serial, result}
		}()
	}

	return result
}

func sort(input string, texts map[string]bool, distances map[string]int, providers, descriptions map[string][]string) [][]string {
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
	p("word complete %v\n", word)
	word.TotalFrequency++
	word.FrequencyByInput[info["input"]]++
	word.FrequencyByFiletype[info["file_type"]]++
	word.FrequencyByFilename[info["file_name"]]++
	word.LatestSelected = time.Now()
	GlobalVocabulary.Unlock()
}
