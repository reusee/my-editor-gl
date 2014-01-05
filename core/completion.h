#include <sys/eventfd.h>
#include <gtk/gtk.h>
#include <glib.h>
#include <stdio.h>
#include <unistd.h>
#include <lua.h>

int fd;

extern callgofunc(void*);

gboolean on_event(GIOChannel *source, GIOCondition cond, gpointer fun) {
	uint64_t i;
	read(fd, &i, sizeof(uint64_t));
	callgofunc((void*)fun);
}

void setup_completion(void *fun) {
  fd = eventfd(0, EFD_SEMAPHORE);
  GIOChannel *chan = g_io_channel_unix_new(fd);
  g_io_add_watch(chan, G_IO_IN, on_event, fun);
}

int emit() {
	uint64_t i = 1;
	write(fd, (void*)&i, sizeof(uint64_t));
}
