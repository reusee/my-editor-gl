package core

import (
	"strings"
	"time"
)

type Vocabulary struct {
	Words map[string]*Word
}

func NewVocabulary() *Vocabulary {
	vocab := &Vocabulary{
		Words: make(map[string]*Word),
	}
	return vocab
}

type Word struct {
	Text                string
	TotalFrequency      int
	FrequencyByInput    map[string]int
	FrequencyByFiletype map[string]int
	FrequencyByFilename map[string]int
	LatestSelected      time.Time
}

func NewWord(text string) *Word {
	word := &Word{
		Text:                text,
		FrequencyByInput:    make(map[string]int),
		FrequencyByFiletype: make(map[string]int),
		FrequencyByFilename: make(map[string]int),
	}
	return word
}

var GlobalVocabulary = NewVocabulary()

func on_found_word(text string) {
	GlobalVocabulary.Add(text)
}

func (self *Vocabulary) Add(text string) {
	if _, has := self.Words[text]; has {
		return
	}
	self.Words[text] = NewWord(text)
}

func get_candidates(input string) [][]string {
	texts := make(map[string]bool)
	providers := make(map[string][]string)
	descriptions := make(map[string][]string)
	distances := make(map[string]int)

	// from GlobalVocabulary
	for _, word := range GlobalVocabulary.Words {
		if match, distance := fuzzyMatch(word.Text, input); match {
			texts[word.Text] = true
			distances[word.Text] = distance
		}
	}

	//TODO extra providers
	_ = providers

	// sort
	max_results := 8
	result := make([][]string, 0, max_results)
	for text, _ := range texts {
		pos := 0
		for _, target := range result { // compare
			if compare(input, GlobalVocabulary.Words[text], GlobalVocabulary.Words[target[0]], distances[text], distances[target[0]], providers) { // win
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
			for i := len(result) - 1; i >= pos + 1; i-- {
				result[i] = result[i - 1]
			}
			result[pos] = []string{text, strings.Join(descriptions[text], "\n")}
		}
	}

	return result
}

func compare(input string, left, right *Word, ldistance, rdistance int, providers map[string][]string) bool {
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

func on_word_completed(info map[string]string) {
	word := GlobalVocabulary.Words[info["text"]]
	word.TotalFrequency++
	word.FrequencyByInput[info["input"]]++
	word.FrequencyByFiletype[info["file_type"]]++
	word.FrequencyByFilename[info["file_name"]]++
	word.LatestSelected = time.Now()
}
