package main

import (
	"log"
	"runtime"
	"time"
)

func init() {
	runtime.GOMAXPROCS(32)
}

func main() {
	lua, err := NewLua("main.lua")
	if err != nil {
		log.Fatal(err)
	}
	for _ = range time.NewTicker(time.Second * 1).C {
		lua.Signal()
	}
}
