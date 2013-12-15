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
	"errors"
	"fmt"
	"log"
	"os"
	"syscall"
	"unsafe"
)

type Lua struct {
	State *C.lua_State
}

func NewLua(filename string) (*Lua, error) {
	// lua state
	state := C.luaL_newstate()
	C.luaL_openlibs(state)

	// load file
	cFilename := C.CString(filename)
	defer C.free(unsafe.Pointer(cFilename))
	if ret := C.luaL_loadfilex(state, cFilename, nil); ret != C.LUA_OK {
		return nil, errors.New(fmt.Sprintf("%s", C.GoString(C.lua_tolstring(state, -1, nil))))
	}

	lua := &Lua{
		State: state,
	}

	// register functions
	wait_init := make(chan bool)
	lua.RegisterClosure("initialized", func() {
		close(wait_init)
	})
	lua.RegisterClosure("exit", func() {
		os.Exit(0)
	})

	// run
	go func() {
		ret := C.lua_pcallk(state, 0, C.LUA_MULTRET, 0, 0, nil)
		if ret != C.LUA_OK {
			log.Fatalf("%s\n", C.GoString(C.lua_tolstring(state, -1, nil)))
		}
	}()
	<-wait_init

	return &Lua{
		State: state,
	}, nil
}

func (self *Lua) Close() {
	C.lua_close(self.State)
}

func (self *Lua) RegisterClosure(name string, fun func()) {
	cName := C.CString(name)
	C.register_function(self.State, cName, unsafe.Pointer(&fun))
	C.free(unsafe.Pointer(cName))
}

func (self *Lua) Signal() {
	syscall.Kill(syscall.Getpid(), syscall.SIGUSR1)
}

//export Invoke
func Invoke(p unsafe.Pointer) {
	(*(*func())(p))()
}
