package extra

//#include <gtk/gtk.h>
//#include <string.h>
//#cgo pkg-config: gtk+-3.0
import "C"

import (
	"../core"
	"bytes"
	"encoding/json"
	"fmt"
	"go/format"
	"log"
	"os/exec"
	"strconv"
	"unicode/utf8"
	"unsafe"
)

var gocodePath = "/home/reus/gopath/bin/gocode"

func golang_setup_completion(providersp unsafe.Pointer) {
	providers := (*core.Providers)(providersp)
	providers.Providers["Go"] = provide
}

func provide(input string, info map[string]interface{}) [][]string {
	buffer := (*C.GtkTextBuffer)(info["buffer"].(unsafe.Pointer))
	filename := info["filename"].(string)
	char_offset := info["char_offset"].(int)
	var start_iter, end_iter C.GtkTextIter
	C.gtk_text_buffer_get_start_iter(buffer, &start_iter)
	C.gtk_text_buffer_get_end_iter(buffer, &end_iter)
	cText := C.gtk_text_buffer_get_text(buffer, &start_iter, &end_iter, C.gtk_false())
	text := C.GoBytes(unsafe.Pointer(cText), C.int(C.strlen((*C.char)(cText))))

	byte_offset := 0
	cur_char_offset := 0
	var size int
	for cur_char_offset != char_offset {
		_, size = utf8.DecodeRune(text[byte_offset:])
		byte_offset += size
		cur_char_offset += 1
	}

	cmd := exec.Command(gocodePath, "-f=json", "autocomplete", filename, strconv.Itoa(byte_offset))
	cmd.Stdin = bytes.NewReader(text)
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		log.Fatalf("gocode run error %v", err)
	}
	var i interface{}
	err = json.Unmarshal(out.Bytes(), &i)
	if err != nil {
		log.Fatalf("gocode json decode error %v", err)
	}
	i2 := i.([]interface{})
	if len(i2) == 0 {
		return nil
	}

	var ret [][]string
	var entry map[string]interface{}
	for _, entryI := range i2[1].([]interface{}) {
		entry = entryI.(map[string]interface{})
		fmt.Printf("===> %s\n", entry["name"].(string))
		ret = append(ret, []string{
			entry["name"].(string),
			entry["class"].(string) + " " + entry["type"].(string),
		})
	}
	return ret
}

func gofmt(src []byte) (string, string) {
	out, err := format.Source(src)
	if err != nil {
		return "", fmt.Sprintf("%v", err)
	}
	return string(out), ""
}
