package core

//#cgo pkg-config: gtksourceview-3.0 gtk+-3.0 lua
//#include <gtk/gtk.h>
import "C"

import (
	"fmt"
	"unsafe"
)

var Registry = map[string]interface{}{
	// completion
	"update_candidates": update_candidates,
	"on_word_completed": on_word_completed,
	"new_providers":     new_providers,
	"setup_completion":  setup_completion,

	// macro
	"copy_event": copy_event,
	"put_event":  put_event,

	// selection
	"draw_selections": draw_selections,

	// snippet
	"split_snippet_line": split_snippet_line,

	// status
	"setup_relative_line_number": setup_relative_line_number,

	// transform
	"set_relative_indicators":   set_relative_indicators,
	"reset_relative_indicators": reset_relative_indicators,

	// view
	"view_is_focus": view_is_focus,

	// vocabulary
	"collect_words": collect_words,
	"compile_regex": compile_regex,
}

func p(format string, args ...interface{}) {
	fmt.Printf(format, args...)
}

//export callgofunc
func callgofunc(p unsafe.Pointer) {
	(*((*func())(p)))()
}

var strs = make(map[string]*C.gchar)

func cstr(str string) *C.gchar {
	if c, ok := strs[str]; ok {
		return c
	}
	c := (*C.gchar)(C.CString(str))
	strs[str] = c
	return c
}
