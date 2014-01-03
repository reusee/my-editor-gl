package lgo

/*
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <string.h>
#cgo pkg-config: lua

void register_function(lua_State*, const char*, void*);
void setup_message_handler(lua_State*);
int traceback(lua_State*);

*/
import "C"

import (
	"fmt"
	"reflect"
	"strings"
	"unsafe"
)

type Lua struct {
	State     *C.lua_State
	Functions map[string]*Function
}

type Function struct {
	name string
	fun  interface{}
	lua  *Lua
}

func NewLua() *Lua {
	state := C.luaL_newstate()
	if state == nil {
		panic("lua state create error")
	}
	C.luaL_openlibs(state)
	lua := &Lua{
		State:     state,
		Functions: make(map[string]*Function),
	}
	return lua
}

func (self *Lua) RegisterFunction(name string, fun interface{}) {
	path := strings.Split(name, ".")
	name = path[len(path)-1]
	path = path[0 : len(path)-1]
	if len(path) == 0 {
		path = append(path, "_G")
	}
	// ensure namespaces
	for i, namespace := range path {
		cNamespace := C.CString(namespace)
		defer C.free(unsafe.Pointer(cNamespace))
		if i == 0 { // top namespace
			C.lua_getglobal(self.State, cNamespace)
			if C.lua_type(self.State, -1) == C.LUA_TNIL { // not exists
				C.lua_settop(self.State, -2)
				C.lua_createtable(self.State, 0, 0)
				C.lua_setglobal(self.State, cNamespace)
				C.lua_getglobal(self.State, cNamespace)
			}
			if C.lua_type(self.State, -1) != C.LUA_TTABLE {
				self.Panic("global %s is not a table", namespace)
			}
		} else { // sub namespace TODO
			C.lua_pushstring(self.State, cNamespace)
			C.lua_rawget(self.State, -2)
			if C.lua_type(self.State, -1) == C.LUA_TNIL {
				C.lua_settop(self.State, -2)
				C.lua_pushstring(self.State, cNamespace)
				C.lua_createtable(self.State, 0, 0)
				C.lua_rawset(self.State, -3)
				C.lua_pushstring(self.State, cNamespace)
				C.lua_rawget(self.State, -2)
			}
			if C.lua_type(self.State, -1) != C.LUA_TTABLE {
				self.Panic("namespace %s is not a table", namespace)
			}
		}
	}
	// register function
	funcType := reflect.TypeOf(fun)
	if funcType.IsVariadic() {
		self.Panic("cannot register variadic function: %v", fun)
	}
	cName := C.CString(name)
	defer C.free(unsafe.Pointer(cName))
	function := &Function{
		fun:  fun,
		lua:  self,
		name: name,
	}
	C.register_function(self.State, cName, unsafe.Pointer(function))
	self.Functions[name] = function
	C.lua_settop(self.State, -2)
}

func (self *Lua) RegisterFunctions(funcs map[string]interface{}) {
	for name, fun := range funcs {
		self.RegisterFunction(name, fun)
	}
}

//export Invoke
func Invoke(p unsafe.Pointer) int {
	function := (*Function)(p)
	lua := function.lua
	funcType := reflect.TypeOf(function.fun)
	// check argument count
	argc := C.lua_gettop(lua.State)
	if int(argc) != funcType.NumIn() {
		lua.Panic("arguments not match: %v", function.fun)
	}
	// arguments
	var args []reflect.Value
	for i := C.int(1); i <= argc; i++ {
		args = append(args, toGoValue(lua, i, funcType.In(int(i-1))))
	}
	// call and returns
	returnValues := reflect.ValueOf(function.fun).Call(args)
	if len(returnValues) != funcType.NumOut() {
		lua.Panic("return values not match: %v", function.fun)
	}
	for _, v := range returnValues {
		pushGoValue(lua, v)
	}
	return len(returnValues)
}

var stringType = reflect.TypeOf("")
var intType = reflect.TypeOf(int(0))

func toGoValue(lua *Lua, i C.int, paramType reflect.Type) (ret reflect.Value) {
	luaType := C.lua_type(lua.State, i)
	paramKind := paramType.Kind()
	switch paramKind {
	case reflect.Bool:
		if luaType != C.LUA_TBOOLEAN {
			lua.Panic("not a boolean")
		}
		ret = reflect.ValueOf(C.lua_toboolean(lua.State, i) == C.int(1))
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		if luaType != C.LUA_TNUMBER {
			lua.Panic("not a integer")
		}
		ret = reflect.New(paramType).Elem()
		ret.SetInt(int64(C.lua_tointegerx(lua.State, i, nil)))
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		if luaType != C.LUA_TNUMBER {
			lua.Panic("not a unsigned")
		}
		ret = reflect.New(paramType).Elem()
		ret.SetUint(uint64(C.lua_tointegerx(lua.State, i, nil)))
	case reflect.Float32, reflect.Float64:
		if luaType != C.LUA_TNUMBER {
			lua.Panic("not a unsigned")
		}
		ret = reflect.New(paramType).Elem()
		ret.SetFloat(float64(C.lua_tonumberx(lua.State, i, nil)))
	case reflect.Interface:
		switch luaType {
		case C.LUA_TNUMBER:
			ret = reflect.New(intType).Elem()
			ret.SetInt(int64(C.lua_tointegerx(lua.State, i, nil)))
		case C.LUA_TSTRING:
			ret = reflect.New(stringType).Elem()
			ret.SetString(C.GoString(C.lua_tolstring(lua.State, i, nil)))
		case C.LUA_TLIGHTUSERDATA:
			ret = reflect.ValueOf(C.lua_topointer(lua.State, i))
		default:
			lua.Panic("wrong interface argument: %v", paramKind)
		}
	case reflect.String:
		if luaType != C.LUA_TSTRING {
			lua.Panic("not a string")
		}
		ret = reflect.New(paramType).Elem()
		ret.SetString(C.GoString(C.lua_tolstring(lua.State, i, nil)))
	case reflect.Slice:
		switch luaType {
		case C.LUA_TSTRING:
			ret = reflect.New(paramType).Elem()
			cstr := C.lua_tolstring(lua.State, i, nil)
			ret.SetBytes(C.GoBytes(unsafe.Pointer(cstr), C.int(C.strlen(cstr))))
		case C.LUA_TTABLE:
			ret = reflect.MakeSlice(paramType, 0, 0)
			C.lua_pushnil(lua.State)
			elemType := paramType.Elem()
			for C.lua_next(lua.State, i) != 0 {
				ret = reflect.Append(ret, toGoValue(lua, -1, elemType))
				C.lua_settop(lua.State, -2)
			}
		default:
			lua.Panic("wrong slice argument")
		}
	case reflect.Ptr:
		if luaType != C.LUA_TLIGHTUSERDATA {
			lua.Panic("not a pointer")
		}
		ret = reflect.ValueOf(C.lua_topointer(lua.State, i))
	case reflect.Map:
		if luaType != C.LUA_TTABLE {
			lua.Panic("not a map")
		}
		ret = reflect.MakeMap(paramType)
		C.lua_pushnil(lua.State)
		keyType := paramType.Key()
		elemType := paramType.Elem()
		for C.lua_next(lua.State, i) != 0 {
			ret.SetMapIndex(
				toGoValue(lua, -2, keyType),
				toGoValue(lua, -1, elemType))
			C.lua_settop(lua.State, -2)
		}
	case reflect.UnsafePointer:
		ret = reflect.ValueOf(C.lua_topointer(lua.State, i))
	default:
		lua.Panic("unknown argument type %v", paramType)
	}
	return
}

func pushGoValue(lua *Lua, value reflect.Value) {
	switch t := value.Type(); t.Kind() {
	case reflect.Bool:
		if value.Bool() {
			C.lua_pushboolean(lua.State, C.int(1))
		} else {
			C.lua_pushboolean(lua.State, C.int(0))
		}
	case reflect.String:
		C.lua_pushstring(lua.State, C.CString(value.String()))
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		C.lua_pushnumber(lua.State, C.lua_Number(C.longlong(value.Int())))
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		C.lua_pushnumber(lua.State, C.lua_Number(C.ulonglong(value.Uint())))
	case reflect.Float32, reflect.Float64:
		C.lua_pushnumber(lua.State, C.lua_Number(C.double(value.Float())))
	case reflect.Slice:
		length := value.Len()
		C.lua_createtable(lua.State, C.int(length), 0)
		for i := 0; i < length; i++ {
			C.lua_pushnumber(lua.State, C.lua_Number(i+1))
			pushGoValue(lua, value.Index(i))
			C.lua_settable(lua.State, -3)
		}
	case reflect.Interface:
		pushGoValue(lua, value.Elem())
	case reflect.Ptr:
		C.lua_pushlightuserdata(lua.State, unsafe.Pointer(value.Pointer()))
	default:
		lua.Panic("wrong return value %v %v", value, t.Kind())
	}
}

func (self *Lua) RunString(code string) {
	defer func() {
		if r := recover(); r != nil {
			print("============ start lua traceback ============\n")
			self.RunString(`print(debug.traceback())`)
			print("============ end lua traceback ==============\n")
			panic(r)
		}
	}()
	cCode := C.CString(code)
	defer C.free(unsafe.Pointer(cCode))
	C.setup_message_handler(self.State)
	if ret := C.luaL_loadstring(self.State, cCode); ret != C.int(0) {
		self.Panic("%s", C.GoString(C.lua_tolstring(self.State, -1, nil)))
	}
	ret := C.lua_pcallk(self.State, 0, 0, C.lua_gettop(self.State)-C.int(1), 0, nil)
	if ret != C.int(0) {
		self.Panic("%s", C.GoString(C.lua_tolstring(self.State, -1, nil)))
	}
}

func (self *Lua) Panic(format string, args ...interface{}) {
	panic(fmt.Sprintf(format, args...))
}
