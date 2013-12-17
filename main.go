package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"os"
	"os/user"
	"path/filepath"
	"runtime"
	"time"
)

func init() {
	runtime.GOMAXPROCS(32)
	rand.Seed(time.Now().UnixNano())
	fmt.Printf("")
}

func main() {
	lua, err := NewLua("main.lua")
	if err != nil {
		log.Fatal(err)
	}

	lua.RegisterFunctions(map[string]interface{}{

		// argv
		"argv": func() []string {
			return os.Args[1:]
		},

		// path utils
		"program_path": func() string {
			abs, _ := filepath.Abs(os.Args[0])
			return filepath.Dir(abs)
		},
		"abspath": func(p string) string {
			abs, _ := filepath.Abs(p)
			return abs
		},
		"dirname": func(p string) string {
			return filepath.Dir(p)
		},
		"splitpath": func(p string) (string, string) {
			return filepath.Split(p)
		},
		"joinpath": func(ps ...string) string {
			res := ""
			for _, part := range ps {
				res = filepath.Join(res, part)
			}
			return res
		},
		"expanduser": func(p string) string {
			home := ""
			user, err := user.Current()
			if err == nil {
				home = user.HomeDir
			}
			parts := filepath.SplitList(p)
			res := ""
			for _, part := range parts {
				if part == "~" {
					res = filepath.Join(res, home)
				} else {
					res = filepath.Join(res, part)
				}
			}
			return res
		},

		// time
		"current_time_in_millisecond": func() int64 {
			t := time.Now().UnixNano() / 1000000
			return t
		},

		// file utils
		"listdir": func(path string) ([]string, bool) {
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
	})

	lua.Run()
}
