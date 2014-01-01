package extra

import (
	"bytes"
	"io/ioutil"
	"runtime/pprof"
)

var profileBuffer bytes.Buffer

func startprofile() {
	profileBuffer.Reset()
	pprof.StartCPUProfile(&profileBuffer)
}

func stopprofile() {
	pprof.StopCPUProfile()
	ioutil.WriteFile("profile", profileBuffer.Bytes(), 0644)
}
