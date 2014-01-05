package core

//#include <gdk/gdk.h>
import "C"

import (
	"unsafe"
)

func copy_event(event unsafe.Pointer) *C.GdkEvent {
	return C.gdk_event_copy((*C.GdkEvent)(event))
}

func put_event(event unsafe.Pointer) {
	C.gdk_event_put((*C.GdkEvent)(event))
}
