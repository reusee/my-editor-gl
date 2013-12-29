package main

/*
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include <stdlib.h>
#include <string.h>
#cgo pkg-config: lua

#include <gtk/gtk.h>
#cgo pkg-config: gtk+-3.0

void register_function(lua_State*, const char*, void*);
void setup_message_handler(lua_State*);

*/
import "C"

import (
	"fmt"
	"log"
	"os"
	"reflect"
	"runtime"
	"unsafe"
)

func init() {
	fmt.Printf("")
}

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
				C.lua_rawgeti(lua.State, C.LUA_REGISTRYINDEX, C.LUA_RIDX_GLOBALS)
				C.lua_getfield(lua.State, -1, luaCallback)
				pushGoValue(lua.State, reflect.ValueOf(res.tag))
				pushGoValue(lua.State, reflect.ValueOf(res.value))
				C.lua_callk(lua.State, 2, 0, 0, nil)
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
	ret := C.lua_pcallk(self.State, 0, 0, C.lua_gettop(self.State)-C.int(1), 0, nil)
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
	fmt.Printf("invoke %s\n", callback.name)
	// arguments
	var args []reflect.Value
	isVariadic := funcType.IsVariadic()
	var paramType reflect.Type
	for i := C.int(1); i <= argc; i++ {
		if !isVariadic {
			paramType = funcType.In(int(i - 1))
		}
		args = append(args, toGoValue(state, i, paramType, isVariadic))
	}
	fmt.Printf("arguments marshaled\n")
	// return values
	funcValue := reflect.ValueOf(callback.fun)
	returnValues := funcValue.Call(args)
	fmt.Printf("function called\n")
	for _, v := range returnValues {
		pushGoValue(state, v)
	}
	fmt.Printf("return values marshaled\n")
	return len(returnValues)
}

var stringType = reflect.TypeOf("")
var intType = reflect.TypeOf(int(0))

func toGoValue(state *C.lua_State, i C.int, paramType reflect.Type, isVariadic bool) (ret reflect.Value) {
	luaType := C.lua_type(state, i)
	// boolean
	if luaType == C.LUA_TBOOLEAN {
		ret = reflect.ValueOf(C.lua_toboolean(state, i) == C.int(1))
		// int, uint or float
	} else if luaType == C.LUA_TNUMBER {
		switch paramType.Kind() {
		case reflect.Interface:
			ret = reflect.New(intType).Elem()
			ret.SetInt(int64(C.lua_tointegerx(state, i, nil)))
		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
			ret = reflect.New(paramType).Elem()
			ret.SetInt(int64(C.lua_tointegerx(state, i, nil)))
		case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
			ret = reflect.New(paramType).Elem()
			ret.SetUint(uint64(C.lua_tointegerx(state, i, nil)))
		default:
			ret = reflect.New(paramType).Elem()
			ret.SetFloat(float64(C.lua_tonumberx(state, i, nil)))
		}
		// string or slice
	} else if luaType == C.LUA_TSTRING {
		if isVariadic { // variadic string slice
			ret = reflect.ValueOf(C.GoString(C.lua_tolstring(state, i, nil)))
		} else { // string or bytes
			switch paramType.Kind() {
			case reflect.Interface:
				ret = reflect.New(stringType).Elem()
				ret.SetString(C.GoString(C.lua_tolstring(state, i, nil)))
			case reflect.String:
				ret = reflect.New(paramType).Elem()
				ret.SetString(C.GoString(C.lua_tolstring(state, i, nil)))
			case reflect.Slice:
				ret = reflect.New(paramType).Elem()
				cstr := C.lua_tolstring(state, i, nil)
				ret.SetBytes(C.GoBytes(unsafe.Pointer(cstr), C.int(C.strlen(cstr))))
			default:
				log.Fatalf("invalid string argument")
			}
		}
		// pointer
	} else if luaType == C.LUA_TLIGHTUSERDATA {
		ret = reflect.ValueOf(C.lua_topointer(state, i))
		// slice or map
	} else if luaType == C.LUA_TTABLE {
		switch paramType.Kind() {
		case reflect.Slice: // slice
			ret = reflect.MakeSlice(paramType, 0, 0)
			C.lua_pushnil(state)
			elemType := paramType.Elem()
			for C.lua_next(state, i) != 0 {
				ret = reflect.Append(ret, toGoValue(state, -1, elemType, isVariadic))
				C.lua_settop(state, -2)
			}
		case reflect.Map: // map
			ret = reflect.MakeMap(paramType)
			C.lua_pushnil(state)
			keyType := paramType.Key()
			elemType := paramType.Elem()
			for C.lua_next(state, i) != 0 {
				ret.SetMapIndex(
					toGoValue(state, -2, keyType, isVariadic),
					toGoValue(state, -1, elemType, isVariadic))
				C.lua_settop(state, -2)
			}
		default:
			log.Fatalf("cannot assign lua table to %v", paramType)
		}
	} else {
		log.Fatalf("invalid argument type")
	}
	return
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
