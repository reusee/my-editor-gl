package main

//#include <gdk/gdk.h>
//#cgo pkg-config: gtk+-3.0
import "C"

import (
	"./core"
	"./extra"
	"./lgo"
	"bytes"
	"encoding/xml"
	"flag"
	"fmt"
	"io/ioutil"
	"math/rand"
	"os"
	"os/user"
	"path/filepath"
	"regexp"
	"runtime"
	"syscall"
	"time"
	"unicode/utf8"
	"unsafe"
)

var debugFlag = flag.Bool("debug", false, "enable debug")

func init() {
	runtime.GOMAXPROCS(32)
	rand.Seed(time.Now().UnixNano())
	fmt.Printf("")
	flag.Parse()
	// log
	if !*debugFlag {
		_, path, _, _ := runtime.Caller(0)
		logFile, err := os.OpenFile(filepath.Join(filepath.Dir(path), "logs", fmt.Sprintf("%d", time.Now().UnixNano())),
			os.O_WRONLY|os.O_CREATE|os.O_SYNC, 0644)
		if err != nil {
			panic("cannot open log file")
		}
		syscall.Dup2(int(logFile.Fd()), 1)
		syscall.Dup2(int(logFile.Fd()), 2)
	}
}

var t0 = time.Now()

func main() {
	lua := lgo.NewLua()

	lua.RegisterFunctions(map[string]interface{}{
		// sys
		"Sys_argv": func() []string {
			return os.Args[1:]
		},
		"Sys_program_path": func() string {
			_, path, _, _ := runtime.Caller(0)
			return filepath.Dir(path)
		},
		"Sys_home": func() string {
			user, err := user.Current()
			if err != nil {
				return ""
			}
			return user.HomeDir
		},
		"Sys_exit": func() {
			os.Exit(0)
		},

		// path
		"Path_abs": func(p string) string {
			abs, _ := filepath.Abs(p)
			return abs
		},
		"Path_dir": func(p string) string {
			return filepath.Dir(p)
		},
		"Path_base": func(p string) string {
			return filepath.Base(p)
		},
		"Path_split": func(p string) (string, string) {
			return filepath.Split(p)
		},
		"Path_join": func(ps []string) string {
			res := ""
			for _, part := range ps {
				res = filepath.Join(res, part)
			}
			return res
		},
		"Path_sep": func() string {
			return string(os.PathSeparator)
		},

		// time
		"Time_current_time_in_millisecond": func() int64 {
			t := time.Now().UnixNano() / 1000000
			return t
		},
		"Time_tick": func() (ret string) {
			ret = fmt.Sprintf("%v", time.Now().Sub(t0))
			t0 = time.Now()
			return
		},

		// os
		"Os_exists": func(p string) bool {
			_, err := os.Stat(p)
			return err == nil
		},
		"Os_mkdir": func(p string) bool {
			return os.Mkdir(p, 0755) != nil
		},
		"Os_list": func(path string) ([]string, bool) {
			files, err := ioutil.ReadDir(path)
			if err != nil {
				return nil, true
			}
			var names []string
			for _, info := range files {
				names = append(names, info.Name())
			}
			return names, false
		},
		"Os_isdir": func(path string) bool {
			info, err := os.Stat(path)
			if err != nil {
				return false
			}
			return info.IsDir()
		},
		"Os_filemode": func(path string) os.FileMode {
			info, err := os.Stat(path)
			if err != nil {
				return 0
			}
			return info.Mode()
		},
		"Os_createwithmode": func(path string, mode uint32) bool {
			f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, os.FileMode(mode))
			if err != nil {
				return true
			}
			f.Close()
			return false
		},
		"Os_move": func(src, dst string) bool {
			info, err := os.Stat(src)
			if err != nil {
				return true
			}
			mode := info.Mode()
			_, err = os.Stat(dst)
			if err == nil { // dst exists
				return true
			}
			f, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE, mode)
			if err != nil {
				return true
			}
			defer f.Close()
			content, err := ioutil.ReadFile(src)
			if err != nil {
				return true
			}
			f.Write(content)
			return false
		},
		"Os_rename": func(src, dst string) bool {
			return os.Rename(src, dst) != nil
		},

		// text
		"Text_escapemarkup": func(s string) string {
			buf := new(bytes.Buffer)
			err := xml.EscapeText(buf, []byte(s))
			if err != nil {
				return ""
			}
			return string(buf.Bytes())
		},
		"chr": func(r rune) string {
			return string(r)
		},
		"Text_is_valid_utf8": func(input []byte) bool {
			return utf8.Valid(input)
		},

		// regex
		"Regex_index": func(pattern string, content []byte) interface{} {
			re, err := regexp.Compile(pattern)
			if err != nil {
				return false
			}
			indexes := re.FindAllSubmatchIndex(content, -1)
			if indexes == nil {
				return false
			}
			// convert byte index to char index
			byte_index := 0
			char_index := 0
			var size int
			for i, index := range indexes {
				for byte_index != index[0] {
					_, size = utf8.DecodeRune(content[byte_index:])
					byte_index += size
					char_index += 1
				}
				indexes[i][0] = char_index
				for byte_index != index[1] {
					_, size = utf8.DecodeRune(content[byte_index:])
					byte_index += size
					char_index += 1
				}
				indexes[i][1] = char_index
			}
			return indexes
		},
		"Regex_find": func(pattern, content string) (ret []string) {
			re := regexp.MustCompile(pattern)
			if words := re.FindAllString(content, -1); words != nil {
				ret = words
			}
			return
		},

		// gdk & gtk
		"Gdk_copy_event": func(event unsafe.Pointer) *C.GdkEvent {
			return C.gdk_event_copy((*C.GdkEvent)(event))
		},
		"Gdk_put_event": func(event unsafe.Pointer) {
			C.gdk_event_put((*C.GdkEvent)(event))
		},

	})

	lua.RegisterFunctions(core.Registry)
	lua.RegisterFunctions(extra.Registry)

	_, path, _, _ := runtime.Caller(0)
	lua.RunString(`package.path = '` + filepath.Dir(path) + `' .. '/?.lua;' .. package.path`)
	go func() {
		runtime.LockOSThread()
		lua.RunString(`require 'main'`)
	}()

	<-(make(chan bool))
}
