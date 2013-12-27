package core

var Registry = map[string]interface{}{
	// transform
	"set_relative_indicators":  set_relative_indicators,
	"hide_relative_indicators": hide_relative_indicators,

	// view
	"view_is_focus": view_is_focus,
}
