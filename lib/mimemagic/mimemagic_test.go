package mimemagic

import "fmt"
import "os"
import "testing"

func TestFoo(t *testing.T) {
	b := make([]byte, 1024)
	for _, fn := range os.Args {
		f, e := os.Open(fn)
		if e != nil {
			panic(e)
		}
		f.Read(b)
		fmt.Printf("%-30s %s\n", Match("", b), fn)
		f.Close()
	}
}
