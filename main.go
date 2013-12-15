package main

import (
	"log"
	"runtime"
)

func init() {
	runtime.GOMAXPROCS(32)
}

func main() {
	_, err := NewLua("main.lua")
	if err != nil {
		log.Fatal(err)
	}
	loop := make(chan bool)
	<-loop
}
