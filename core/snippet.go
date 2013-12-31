package core

import (
	"regexp"
)

var snippet_control_regex = regexp.MustCompile(`\$[0-9><]+`)

func split_snippet_line(line string) (ret [][]string) {
	i := 0
	var loc []int
	for {
		loc = snippet_control_regex.FindStringIndex(line[i:])
		if loc == nil {
			break
		}
		if loc[0] > 0 { // literal
			ret = append(ret, []string{"l", line[i : i+loc[0]]})
		}
		ret = append(ret, []string{"c", line[i+loc[0] : i+loc[1]]}) // control
		i += loc[1]
	}
	if i < len(line) { // literal
		ret = append(ret, []string{"l", line[i:]})
	}
	return
}
