package core

//#include <gtk/gtk.h>
import "C"

import (
	"regexp"
	"sync"
	"time"
	"unicode/utf8"
	"unsafe"
)

type Vocabulary struct {
	sync.RWMutex
	Words map[string]*Word
	Texts []string
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

func (self *Vocabulary) Add(text string) {
	self.Lock()
	defer self.Unlock()
	if _, has := self.Words[text]; has {
		return
	}
	self.Words[text] = NewWord(text)
	self.Texts = append(self.Texts, text)
}

var compiled_regex_bin []*regexp.Regexp

func compile_regex(p string) *regexp.Regexp {
	re := regexp.MustCompile(p)
	compiled_regex_bin = append(compiled_regex_bin, re)
	return re
}

func collect_words(bufferp unsafe.Pointer, isEditMode bool, rep unsafe.Pointer) {
	var start_iter, end_iter C.GtkTextIter
	buf := (*C.GtkTextBuffer)(bufferp)
	C.gtk_text_buffer_get_start_iter(buf, &start_iter)
	C.gtk_text_buffer_get_end_iter(buf, &end_iter)
	text := []byte(C.GoString((*C.char)(C.gtk_text_buffer_get_text(buf, &start_iter, &end_iter, C.gtk_false()))))
	C.gtk_text_buffer_get_iter_at_mark(buf, &start_iter, C.gtk_text_buffer_get_insert(buf))
	cursor_char_offset := int(C.gtk_text_iter_get_offset(&start_iter))
	go func() {
		byte_offset := 0
		char_offset := 0
		re := (*regexp.Regexp)(rep)
		decode_byte_offset := 0
		var word_start_char_offset, word_end_char_offset int
		var size int
		for {
			// find next word
			loc := re.FindIndex(text[byte_offset:])
			if loc == nil {
				return
			}
			// convert byte offset to char offset
			byte_offset += loc[0]
			for decode_byte_offset < byte_offset {
				_, size = utf8.DecodeRune(text[decode_byte_offset:])
				decode_byte_offset += size
				char_offset += 1
			}
			word_start_char_offset = char_offset
			byte_offset += loc[1] - loc[0]
			for decode_byte_offset < byte_offset {
				_, size = utf8.DecodeRune(text[decode_byte_offset:])
				decode_byte_offset += size
				char_offset += 1
			}
			word_end_char_offset = char_offset
			// skip current word in edit mode
			if isEditMode {
				if cursor_char_offset >= word_start_char_offset && cursor_char_offset <= word_end_char_offset {
					continue
				}
			}
			// add to global vocabulary
			GlobalVocabulary.Add(string(text[byte_offset-(loc[1]-loc[0]) : byte_offset]))
		}
	}()
}
