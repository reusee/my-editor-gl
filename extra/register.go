package extra

var Registry = map[string]interface{}{
	"get_gocode_completions": get_gocode_completions,
	"gofmt":                  gofmt,
}
