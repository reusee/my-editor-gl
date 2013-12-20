package main

/*
#include "luajit/src/lua.h"
#include "luajit/src/lualib.h"
#include "luajit/src/lauxlib.h"
#include <stdlib.h>
#include <string.h>
#cgo LDFLAGS: luajit/src/libluajit.a -lm -ldl

#include <gtk/gtk.h>
#cgo pkg-config: gtk+-3.0

void register_function(lua_State*, const char*, void*);
void setup_message_handler(lua_State*);

*/
import "C"

import (
	"log"
	"os"
	"reflect"
	"runtime"
	"unsafe"
)

type Result struct {
	tag   string
	value interface{}
}

type Lua struct {
	State     *C.lua_State
	callbacks []*Callback
	filename  string
	Results   chan *Result
}

func NewLua(filename string) (*Lua, error) {
	// lua state
	state := C.luaL_newstate()
	C.luaL_openlibs(state)

	lua := &Lua{
		State:    state,
		filename: filename,
		Results:  make(chan *Result, 512),
	}

	lua.RegisterFunction("main_loop", func() {
		luaCallback := C.CString("process_go_result")
		for {
			C.gtk_main_iteration()
			select {
			case res := <-lua.Results:
				C.lua_getfield(lua.State, C.LUA_GLOBALSINDEX, luaCallback)
				pushGoValue(lua.State, reflect.ValueOf(res.tag))
				pushGoValue(lua.State, reflect.ValueOf(res.value))
				C.lua_call(lua.State, 2, 0)
			default:
			}
		}
	})

	lua.RegisterFunction("main_quit", func() {
		os.Exit(0)
	})

	return lua, nil
}

func (self *Lua) Run() {
	runtime.LockOSThread()
	// message handler
	C.setup_message_handler(self.State)
	// load file
	cFilename := C.CString(self.filename)
	defer C.free(unsafe.Pointer(cFilename))
	if ret := C.luaL_loadfilex(self.State, cFilename, nil); ret != C.int(0) {
		log.Fatalf("%s", C.GoString(C.lua_tolstring(self.State, -1, nil)))
	}
	// run
	ret := C.lua_pcall(self.State, 0, 0, C.lua_gettop(self.State)-C.int(1))
	if ret != C.int(0) {
		log.Fatalf("%s\n", C.GoString(C.lua_tolstring(self.State, -1, nil)))
	}
	os.Exit(0)
}

func (self *Lua) RegisterFunctions(funcs map[string]interface{}) {
	for name, fun := range funcs {
		self.RegisterFunction(name, fun)
	}
}

func (self *Lua) RegisterFunction(name string, fun interface{}) {
	cName := C.CString(name)
	callback := &Callback{
		fun:   fun,
		state: self.State,
		name:  name,
	}
	C.register_function(self.State, cName, unsafe.Pointer(callback))
	self.callbacks = append(self.callbacks, callback) // to avoid gc
	C.free(unsafe.Pointer(cName))
}

type Callback struct {
	fun   interface{}
	state *C.lua_State
	name  string
}

//export Invoke
func Invoke(p unsafe.Pointer) int {
	callback := (*Callback)(p)
	state := callback.state
	argc := C.lua_gettop(state)
	funcType := reflect.TypeOf(callback.fun)
	numIn := funcType.NumIn()
	if !funcType.IsVariadic() && int(argc) != numIn {
		log.Fatalf("arguments not match: %v %v %v",
			callback.fun, int(argc), numIn)
	}
	// arguments
	var args []reflect.Value
	for i := C.int(1); i <= argc; i++ {
		var value reflect.Value
		if C.lua_type(state, i) == C.LUA_TBOOLEAN {
			value = reflect.ValueOf(C.lua_toboolean(state, i) == C.int(1))
		} else if C.lua_type(state, i) == C.LUA_TNUMBER {
			paramType := funcType.In(int(i - 1))
			value = reflect.New(paramType).Elem()
			switch paramType.Kind() {
			case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
				value.SetInt(int64(C.lua_tointeger(state, i)))
			case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
				value.SetUint(uint64(C.lua_tointeger(state, i)))
			default:
				value.SetFloat(float64(C.lua_tonumber(state, i)))
			}
		} else if C.lua_type(state, i) == C.LUA_TSTRING {
			if funcType.IsVariadic() { // variadic string slice
				value = reflect.ValueOf(C.GoString(C.lua_tolstring(state, i, nil)))
			} else { // string or bytes
				paramType := funcType.In(int(i - 1))
				value = reflect.New(paramType).Elem()
				switch paramType.Kind() {
				case reflect.String:
					value.SetString(C.GoString(C.lua_tolstring(state, i, nil)))
				case reflect.Slice:
					cstr := C.lua_tolstring(state, i, nil)
					value.SetBytes(C.GoBytes(unsafe.Pointer(cstr), C.int(C.strlen(cstr))))
				default:
					log.Fatalf("invalid string argument")
				}
			}
		} else if C.lua_type(state, i) == C.LUA_TLIGHTUSERDATA {
			value = reflect.ValueOf(C.lua_topointer(state, i))
		} else {
			log.Fatalf("invalid argument type: %v %d", callback.fun, int(i))
		}
		args = append(args, value)
	}
	// return values
	funcValue := reflect.ValueOf(callback.fun)
	returnValues := funcValue.Call(args)
	for _, v := range returnValues {
		pushGoValue(state, v)
	}
	return len(returnValues)
}

func pushGoValue(state *C.lua_State, value reflect.Value) {
	switch t := value.Type(); t.Kind() {
	case reflect.Bool:
		if value.Bool() {
			C.lua_pushboolean(state, C.int(1))
		} else {
			C.lua_pushboolean(state, C.int(0))
		}
	case reflect.String:
		C.lua_pushstring(state, C.CString(value.String()))
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		C.lua_pushnumber(state, C.lua_Number(C.longlong(value.Int())))
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		C.lua_pushnumber(state, C.lua_Number(C.ulonglong(value.Uint())))
	case reflect.Float32, reflect.Float64:
		C.lua_pushnumber(state, C.lua_Number(C.double(value.Float())))
	case reflect.Slice:
		length := value.Len()
		C.lua_createtable(state, C.int(length), 0)
		for i := 0; i < length; i++ {
			C.lua_pushnumber(state, C.lua_Number(i+1))
			pushGoValue(state, value.Index(i))
			C.lua_settable(state, -3)
		}
	case reflect.Interface:
		pushGoValue(state, value.Elem())
	case reflect.Ptr:
		C.lua_pushlightuserdata(state, unsafe.Pointer(value.Pointer()))
	default:
		log.Fatalf("wrong return value %v %v", value, t.Kind())
	}
}
