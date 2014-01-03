#include "lua.h"

int invoke_go_func(lua_State* state) {
  void* p = lua_touserdata(state, lua_upvalueindex(1));
  return Invoke(p);
}

void register_function(lua_State* state, const char* name, void* func) {
  lua_pushstring(state, name);
  lua_pushlightuserdata(state, func);
  lua_pushcclosure(state, (lua_CFunction)invoke_go_func, 1);
  lua_rawset(state, -3);
}

int traceback(lua_State* L) {
	lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
  lua_getfield(L, -1, "debug");
  lua_getfield(L, -1, "traceback");
  lua_pushvalue(L, 1);
  lua_pushinteger(L, 2);
  lua_callk(L, 2, 1, 0, NULL);
  return 1;
}

void setup_message_handler(lua_State* L) {
  lua_pushcfunction(L, traceback);
}
