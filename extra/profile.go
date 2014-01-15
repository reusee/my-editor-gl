package extra

import (
	"bytes"
	"io/ioutil"
	"net/http"
	_ "net/http/pprof"
	"runtime/pprof"
)

func init() {
	go func() {
		http.ListenAndServe("127.0.0.1:65432", nil)
	}()
}

var profileBuffer bytes.Buffer

func start_go_profile() {
	profileBuffer.Reset()
	pprof.StartCPUProfile(&profileBuffer)
}

func stop_go_profile() {
	pprof.StopCPUProfile()
	ioutil.WriteFile("profile", profileBuffer.Bytes(), 0644)
}
