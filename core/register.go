package core

var Registry = map[string]interface{}{
	// completion
	"on_word_completed": on_word_completed,
	"word_rank":         word_rank,

	// status
	"setup_relative_line_number": setup_relative_line_number,

	// transform
	"set_relative_indicators":  set_relative_indicators,
	"hide_relative_indicators": hide_relative_indicators,

	// view
	"view_is_focus": view_is_focus,
}
