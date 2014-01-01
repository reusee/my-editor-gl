package extra

import (
	"fmt"
)

var Registry = map[string]interface{}{
	// golang
	"gofmt":                   gofmt,
	"golang_setup_completion": golang_setup_completion,

	// lua
	"lua_check_parse_error": lua_check_parse_error,

	// profiler
	"startprofile": startprofile,
	"stopprofile":  stopprofile,

	// the silver searcher
	"run_the_silver_searcher": run_the_silver_searcher,
}

func p(format string, args ...interface{}) {
	fmt.Printf(format, args...)
}
