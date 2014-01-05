package core

//#include "status.h"
import "C"

import (
	"unsafe"
)

func setup_relative_line_number(viewp unsafe.Pointer) {
	C.setup_relative_line_number(viewp)
}
