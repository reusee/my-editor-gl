package core

//#include "status.h"
//#cgo pkg-config: gtksourceview-3.0
import "C"

import (
	"unsafe"
)

func setup_relative_line_number(viewp unsafe.Pointer) {
	C.setup_relative_line_number(viewp)
}
