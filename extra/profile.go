package extra

import (
	"bytes"
	"io/ioutil"
	"runtime/pprof"
)

var profileBuffer bytes.Buffer

func start_go_profile() {
	profileBuffer.Reset()
	pprof.StartCPUProfile(&profileBuffer)
}

func stop_go_profile() {
	pprof.StopCPUProfile()
	ioutil.WriteFile("profile", profileBuffer.Bytes(), 0644)
}
