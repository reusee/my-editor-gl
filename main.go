package main

import (
	"fmt"
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
		"abs_path": func(p string) string {
			abs, _ := filepath.Abs(p)
			return abs
		},

		// time
		"current_time_in_millisecond": func() int64 {
			t := time.Now().UnixNano() / 1000000
			return t
		},
	})

	lua.Run()
}
