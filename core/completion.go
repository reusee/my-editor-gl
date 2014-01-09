package core

/*
#include <string.h>
#include <sys/eventfd.h>
#include <gtk/gtk.h>
#include <glib.h>
#include <stdio.h>
#include <unistd.h>
#include <lua.h>

int fd;

extern callgofunc(void*);

gboolean on_event(GIOChannel *source, GIOCondition cond, gpointer fun) {
	uint64_t i;
	read(fd, &i, sizeof(uint64_t));
	callgofunc((void*)fun);
}

void setup_completion(void *fun) {
  fd = eventfd(0, EFD_SEMAPHORE);
  GIOChannel *chan = g_io_channel_unix_new(fd);
  g_io_add_watch(chan, G_IO_IN, on_event, fun);
}

int emit() {
	uint64_t i = 1;
	write(fd, (void*)&i, sizeof(uint64_t));
}

void init_string_value(GValue* value) {
  g_value_init(value, G_TYPE_STRING);
}
*/
import "C"

import (
	"github.com/reusee/lgo"
	"strings"
	"sync"
	"time"
	"unsafe"
)

// async result

type Result struct {
	serial     int
	candidates [][]string
}

var Lua *lgo.Lua
var results = make(chan Result, 1024)
var Store *C.GtkListStore

var fun = func() {
	res := <-results
	Lua.CallFunction("async_update_candidates", res.serial, res.candidates)
}

func setup_completion(lua *lgo.Lua, store unsafe.Pointer) {
	Lua = lua
	Store = (*C.GtkListStore)(store)
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

func update_candidates(serial int, input string, providersp unsafe.Pointer, info map[string]interface{}) {
	texts := make(map[string]bool)
	providers := make(map[string][]string)
	descriptions := make(map[string][]string)
	distances := make(map[string]int)
	var lock sync.Mutex

	// from GlobalVocabulary
	l := GlobalVocabulary.Len()
	var word *Word
	for i := 0; i < l; i++ {
		word = GlobalVocabulary.GetByIndex(i)
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

	updateStore(result)

}

func updateStore(result [][]string) {
	var iter C.GtkTreeIter
	var value C.GValue
	C.init_string_value(&value)
	for _, entry := range result {
		C.gtk_list_store_append(Store, &iter)
		C.g_value_set_static_string(&value, cstr(entry[0]))
		C.gtk_list_store_set_value(Store, &iter, 0, &value)
		C.g_value_set_static_string(&value, cstr(entry[1]))
		C.gtk_list_store_set_value(Store, &iter, 1, &value)
	}
}

func sort(input string, texts map[string]bool, distances map[string]int, providers, descriptions map[string][]string) [][]string {
	max_results := 8
	result := make([][]string, 0, max_results)
	var left, right *Word
	for text := range texts {
		pos := 0
		for _, target := range result { // compare
			left = GlobalVocabulary.Get(text)
			right = GlobalVocabulary.Get(target[0])
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
	word := GlobalVocabulary.Get(info["text"])
	word.Lock()
	defer word.Unlock()
	word.TotalFrequency++
	word.FrequencyByInput[info["input"]]++
	word.FrequencyByFiletype[info["file_type"]]++
	word.FrequencyByFilename[info["file_name"]]++
	word.LatestSelected = time.Now()
}
