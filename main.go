package main

import (
	"log"
	"math/rand"
	"os"
	"path/filepath"
	"runtime"
	"time"
)

func init() {
	runtime.GOMAXPROCS(32)
	rand.Seed(time.Now().UnixNano())
}

func main() {
	lua, err := NewLua("main.lua")
	if err != nil {
		log.Fatal(err)
	}

	lua.RegisterFunctions(map[string]interface{}{

		// argv
		"argv": func() string {
			return "foo bar baz" // TODO
		},

		// path utils
		"program_path": func() string {
			abs, _ := filepath.Abs(os.Args[0])
			return filepath.Dir(abs)
		},
		"abs_path": func(p string) string {
			abs, _ := filepath.Abs(p)
			return abs
		},
	})

	lua.Run()
}
