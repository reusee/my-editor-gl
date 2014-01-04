#include <sys/eventfd.h>
#include <gtk/gtk.h>
#include <glib.h>
#include <stdio.h>
#include <unistd.h>
#include <lua.h>

int fd;
lua_State *L;

gboolean on_event(GIOChannel *source, GIOCondition cond, gpointer data) {
	uint64_t i;
	read(fd, &i, sizeof(uint64_t));
	lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
	lua_getfield(L, -1, "append_candidates");
	lua_callk(L, 0, 0, 0, NULL);
}

void setup_completion(lua_State *state) {
  L = state;
  fd = eventfd(0, EFD_SEMAPHORE);
  GIOChannel *chan = g_io_channel_unix_new(fd);
  g_io_add_watch(chan, G_IO_IN, on_event, NULL);
}

int emit() {
	uint64_t i = 1;
	write(fd, (void*)&i, sizeof(uint64_t));
}
