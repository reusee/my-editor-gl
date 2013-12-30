package extra

import (
	"bytes"
	"log"
	"os/exec"
	"strconv"
	"strings"
)

func lua_check_parse_error(code []byte) (int, string) {
	cmd := exec.Command("/usr/bin/env", "luac", "-p", "-")
	cmd.Stdin = bytes.NewReader(code)
	var out bytes.Buffer
	cmd.Stderr = &out
	err := cmd.Run()
	if err != nil {
		result := string(out.Bytes())
		n, err := strconv.Atoi(strings.Split(result, ":")[2])
		if err != nil {
			log.Fatal(err)
		}
		return n, strings.TrimSpace(result)
	}
	return 0, ""
}
