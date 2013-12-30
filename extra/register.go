package extra

var Registry = map[string]interface{}{
	"gofmt":                   gofmt,
	"golang_setup_completion": golang_setup_completion,

	"lua_check_parse_error": lua_check_parse_error,
}
