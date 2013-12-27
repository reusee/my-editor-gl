package core

//#include <gtk/gtk.h>
import "C"

import (
	"unsafe"
)

func view_is_focus(viewp unsafe.Pointer) bool {
	return C.gtk_widget_is_focus((*C.GtkWidget)(viewp)) == C.gtk_true()
}
