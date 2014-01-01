package extra

import (
	"fmt"
)

var Registry = map[string]interface{}{
	"gofmt":                   gofmt,
	"golang_setup_completion": golang_setup_completion,

	"lua_check_parse_error": lua_check_parse_error,

	"run_the_silver_searcher": run_the_silver_searcher,
}

func p(format string, args ...interface{}) {
	fmt.Printf(format, args...)
}
