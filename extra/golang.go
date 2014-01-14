package extra

import (
	"bytes"
	"encoding/json"
	"fmt"
	"go/format"
	"log"
	"os/exec"
	"strconv"
	"unicode/utf8"
	"unsafe"

	"../core"
	"code.google.com/p/go.tools/imports"
)

// completion

var gocodePath = "/home/reus/gopath/bin/gocode"

func golang_setup_completion(providersp unsafe.Pointer) {
	providers := (*core.Providers)(providersp)
	providers.Providers["Go"] = provide
}

var last_provided [][]string

func provide(input string, text []byte, info map[string]interface{}) [][]string {
	char_offset := info["char_offset"].(int)
	byte_offset := 0
	cur_char_offset := 0
	var size int
	for cur_char_offset != char_offset {
		_, size = utf8.DecodeRune(text[byte_offset:])
		byte_offset += size
		cur_char_offset += 1
	}

	filename := info["filename"].(string)
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
		return last_provided
	}

	var ret [][]string
	var entry map[string]interface{}
	for _, entryI := range i2[1].([]interface{}) {
		entry = entryI.(map[string]interface{})
		ret = append(ret, []string{
			entry["name"].(string),
			entry["class"].(string) + " " + entry["type"].(string),
		})
	}
	last_provided = ret
	return ret
}

// gofmt

func gofmt(src []byte) (string, string) {
	out, err := format.Source(src)
	if err != nil {
		return "", fmt.Sprintf("%v", err)
	}
	return string(out), ""
}

// goimports

func goimports(src []byte) (string, string) {
	out, err := imports.Process("", src, nil)
	if err != nil {
		return "", fmt.Sprintf("%v", err)
	}
	return string(out), ""
}
