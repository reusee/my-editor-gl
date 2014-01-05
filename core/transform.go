package core

//#include <gtk/gtk.h>
import "C"

import (
	"unsafe"
)

func set_relative_indicators(bufp unsafe.Pointer, viewp unsafe.Pointer, offsets []int, indicators []unsafe.Pointer) {
	buf := (*C.GtkTextBuffer)(bufp)
	view := (*C.GtkTextView)(viewp)
	var it C.GtkTextIter
	C.gtk_text_buffer_get_start_iter(buf, &it)
	var location C.GdkRectangle
	var left, top C.gint
	var indicator *C.GtkWidget
	for i, offset := range offsets {
		C.gtk_text_iter_set_offset(&it, C.gint(offset))
		C.gtk_text_view_get_iter_location(view, &it, &location)
		C.gtk_text_view_buffer_to_window_coords(view, C.GTK_TEXT_WINDOW_WIDGET, C.gint(location.x), C.gint(location.y), &left, &top)
		indicator = (*C.GtkWidget)(indicators[i])
		top += 8
		if left >= C.gint(0) && top >= C.gint(0) {
			C.gtk_widget_set_margin_start(indicator, left)
			C.gtk_widget_set_margin_top(indicator, top)
			C.gtk_widget_show(indicator)
		}
	}
}

func reset_relative_indicators(indicators []unsafe.Pointer) {
	for _, indicator := range indicators {
		C.gtk_widget_set_margin_start((*C.GtkWidget)(indicator), C.gint(0))
		C.gtk_widget_set_margin_top((*C.GtkWidget)(indicator), C.gint(0))
	}
}
