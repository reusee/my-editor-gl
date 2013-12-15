package main

/*
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stdlib.h>
#cgo pkg-config: lua

void register_function(lua_State*, const char*, void*);

*/
import "C"

import (
	"fmt"
	"log"
	"os"
	"runtime"
	"syscall"
	"time"
	"unsafe"
)

func init() {
	runtime.GOMAXPROCS(32)
}

func main() {
	// lua state
	state := C.luaL_newstate()
	defer C.lua_close(state)
	C.luaL_openlibs(state)

	// load file
	filename := "main.lua"
	cstr(filename, func(cFilename *C.char) {
		if ret := C.luaL_loadfilex(state, cFilename, nil); ret != C.LUA_OK {
			fmt.Printf("%s\n", C.GoString(C.lua_tolstring(state, -1, nil)))
			log.Fatalf("cannot load file %s", filename)
		}
	})

	// register functions
	wait_init := make(chan bool)
	RegisterClosure(state, "initialized", func() {
		close(wait_init)
	})
	RegisterClosure(state, "exit", func() {
		os.Exit(0)
	})

	// run
	go func() {
		ret := C.lua_pcallk(state, 0, C.LUA_MULTRET, 0, 0, nil)
		if ret != C.LUA_OK {
			fmt.Printf("%s\n", C.GoString(C.lua_tolstring(state, -1, nil)))
		}
	}()
	<-wait_init

	for _ = range time.NewTicker(time.Second * 1).C {
		syscall.Kill(syscall.Getpid(), syscall.SIGUSR1)
	}

}

//export Invoke
func Invoke(p unsafe.Pointer) {
	(*(*func())(p))()
}

func RegisterClosure(state *C.lua_State, name string, fun func()) {
	cName := C.CString(name)
	C.register_function(state, cName, unsafe.Pointer(&fun))
	C.free(unsafe.Pointer(cName))
}

func cstr(s string, fun func(*C.char)) {
	cs := C.CString(s)
	fun(cs)
	C.free(unsafe.Pointer(cs))
}
