package core

import (
	"fmt"
)

var Registry = map[string]interface{}{
	// completion
	"on_found_word":     on_found_word,
	"get_candidates":    get_candidates,
	"on_word_completed": on_word_completed,
	"new_providers":     new_providers,

	// selection
	"draw_selections": draw_selections,

	// status
	"setup_relative_line_number": setup_relative_line_number,

	// transform
	"set_relative_indicators":  set_relative_indicators,
	"hide_relative_indicators": hide_relative_indicators,

	// view
	"view_is_focus": view_is_focus,
}

func p(format string, args ...interface{}) {
	fmt.Printf(format, args...)
}
