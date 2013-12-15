package main

/*
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stdlib.h>
#cgo pkg-config: luajit

void register_function(lua_State*, const char*, void*);

*/
import "C"

import (
	"errors"
	"fmt"
	"log"
	"os"
	"reflect"
	"runtime"
	"time"
	"unsafe"
)

type Lua struct {
	State     *C.lua_State
	callbacks []*Callback
	jobs      []func()
}

func NewLua(filename string) (*Lua, error) {
	// lua state
	state := C.luaL_newstate()
	C.luaL_openlibs(state)

	// load file
	cFilename := C.CString(filename)
	defer C.free(unsafe.Pointer(cFilename))
	if ret := C.luaL_loadfilex(state, cFilename, nil); ret != C.int(0) {
		return nil, errors.New(fmt.Sprintf("%s", C.GoString(C.lua_tolstring(state, -1, nil))))
	}

	lua := &Lua{
		State: state,
	}

	lua.RegisterFunction("test_lua_go", func(i, j int, f float64, b bool, s string) (int, bool, string, float64) {
		return i + j, b, fmt.Sprintf("%v", time.Now()), f
	})

	lua.RegisterFunction("check_jobs", lua.CheckJobs)

	return lua, nil
}

func (self *Lua) Run() {
	runtime.LockOSThread()
	// run
	ret := C.lua_pcall(self.State, 0, C.LUA_MULTRET, 0)
	if ret != C.int(0) {
		log.Fatalf("%s\n", C.GoString(C.lua_tolstring(self.State, -1, nil)))
	}
	os.Exit(0)
}

func (self *Lua) Close() {
	C.lua_close(self.State)
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
	}
	C.register_function(self.State, cName, unsafe.Pointer(callback))
	self.callbacks = append(self.callbacks, callback) // to avoid gc
	C.free(unsafe.Pointer(cName))
}

func (self *Lua) QueueJob(fun func()) {
	self.jobs = append(self.jobs, fun)
}

func (self *Lua) CheckJobs() {
	if len(self.jobs) > 0 {
		job := self.jobs[len(self.jobs)-1]
		job()
		self.jobs = self.jobs[:len(self.jobs)-1]
	}
}

type Callback struct {
	fun   interface{}
	state *C.lua_State
}

//export Invoke
func Invoke(p unsafe.Pointer) int {
	callback := (*Callback)(p)
	state := callback.state
	argc := C.lua_gettop(state)
	funcType := reflect.TypeOf(callback.fun)
	numIn := funcType.NumIn()
	if int(argc) != numIn {
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
			case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64,
				reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
				value.SetInt(int64(C.lua_tointeger(state, i)))
			default:
				value.SetFloat(float64(C.lua_tonumber(state, i)))
			}
		} else if C.lua_type(state, i) == C.LUA_TSTRING {
			value = reflect.ValueOf(C.GoString(C.lua_tolstring(state, i, nil)))
		} else {
			log.Fatalf("invalid argument type: %v %d", callback.fun, int(i))
		}
		args = append(args, value)
	}
	// return values
	funcValue := reflect.ValueOf(callback.fun)
	returnValues := funcValue.Call(args)
	for _, value := range returnValues {
		switch value.Type().Kind() {
		case reflect.Bool:
			if value.Bool() {
				C.lua_pushboolean(state, C.int(1))
			} else {
				C.lua_pushboolean(state, C.int(0))
			}
		case reflect.String:
			C.lua_pushstring(state, C.CString(value.String()))
		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64,
			reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
			C.lua_pushnumber(state, C.lua_Number(C.longlong(value.Int())))
		case reflect.Float32, reflect.Float64:
			C.lua_pushnumber(state, C.lua_Number(C.double(value.Float())))
		}
	}
	return len(returnValues)
}
