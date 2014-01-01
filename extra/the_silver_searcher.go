package extra

import (
	"bytes"
	"os/exec"
	"strings"
)

func run_the_silver_searcher(pattern, dir, option string) ([]string, string) {
	args := []string{"ag", "--ackmate", "--nobreak"}
	option = strings.TrimSpace(option)
	if option != "" {
		options := strings.Split(option, " ")
		args = append(args, options...)
	}
	args = append(args, pattern)
	args = append(args, dir)
	cmd := exec.Command("/usr/bin/env", args...)
	var out bytes.Buffer
	cmd.Stdout = &out
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		return nil, string(stderr.Bytes())
	}
	errmsg := string(stderr.Bytes())
	if errmsg != "" {
		return nil, errmsg
	}
	return strings.Split(string(out.Bytes()), "\n"), ""
}
