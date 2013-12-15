package main

/*
#include <lua.h>
#include <stdlib.h>

int invoke_go_func(lua_State* state) {
  void* p = lua_touserdata(state, lua_upvalueindex(1));
  //TODO pass arguments and get return value
  Invoke(p);
  return 0;
}

void register_function(lua_State* state, const char* name, void* func) {
  lua_pushlightuserdata(state, func);
  lua_pushcclosure(state, (lua_CFunction)invoke_go_func, 1);
  lua_setglobal(state, name);
}

*/
import "C"
