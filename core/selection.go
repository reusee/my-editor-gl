package core

//#include <gtk/gtk.h>
//#include <cairo.h>
import "C"

import (
	"unsafe"
)

func draw_selections(viewp, bufferp, crp unsafe.Pointer, mark_pairs []unsafe.Pointer) {
	view := (*C.GtkTextView)(viewp)
	buffer := (*C.GtkTextBuffer)(bufferp)
	cr := (*C.cairo_t)(crp)
	var alloc C.GtkAllocation
	C.gtk_widget_get_allocation((*C.GtkWidget)(viewp), &alloc)
	n := len(mark_pairs)
	var start_mark, stop_mark *C.GtkTextMark
	var location C.GdkRectangle
	var iter C.GtkTextIter
	var x, y C.gint
	var dx, dy C.double
	for i := 0; i < n; i += 2 {
		start_mark = (*C.GtkTextMark)(mark_pairs[i])
		C.gtk_text_buffer_get_iter_at_mark(buffer, &iter, start_mark)
		C.gtk_text_view_get_iter_location(view, &iter, &location)
		C.gtk_text_view_buffer_to_window_coords(view, C.GTK_TEXT_WINDOW_WIDGET, C.gint(location.x), C.gint(location.y), &x, &y)
		if C.int(x) > alloc.width || C.int(y) > alloc.height || x < 0 || y < 0 {
			continue
		}
		dx = C.double(x)
		dy = C.double(y)

		C.cairo_set_source_rgb(cr, 1, 0, 0)
		C.cairo_move_to(cr, dx, dy)
		C.cairo_set_line_width(cr, 2)
		C.cairo_line_to(cr, dx+6, dy)
		C.cairo_stroke(cr)

		C.cairo_move_to(cr, dx, dy)
		C.cairo_set_line_width(cr, 1)
		C.cairo_line_to(cr, dx, dy+C.double(location.height))
		C.cairo_stroke(cr)

		stop_mark = (*C.GtkTextMark)(mark_pairs[i+1])
		C.gtk_text_buffer_get_iter_at_mark(buffer, &iter, stop_mark)
		C.gtk_text_view_get_iter_location(view, &iter, &location)
		C.gtk_text_view_buffer_to_window_coords(view, C.GTK_TEXT_WINDOW_WIDGET, C.gint(location.x), C.gint(location.y), &x, &y)
		if C.int(x) > alloc.width || C.int(y) > alloc.height || x < 0 || y < 0 {
			continue
		}
		dx = C.double(x)
		dy = C.double(y)

		C.cairo_set_source_rgb(cr, 0, 1, 0)
		C.cairo_move_to(cr, dx, dy)
		C.cairo_set_line_width(cr, 1)
		C.cairo_line_to(cr, dx, dy+C.double(location.height))
		C.cairo_stroke(cr)

		C.cairo_move_to(cr, dx, dy+C.double(location.height))
		C.cairo_set_line_width(cr, 2)
		C.cairo_line_to(cr, dx-6, dy+C.double(location.height))
		C.cairo_stroke(cr)

	}
}
