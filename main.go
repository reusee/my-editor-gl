package main

import (
	"fmt"
	"log"
	"math/rand"
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

	go func() {
		for _ = range time.NewTicker(time.Millisecond * 200).C {
			lua.QueueJob(func() {
				fmt.Printf("heartbeat %v\n", time.Now())
			})
		}
	}()

	lua.Run()
}
