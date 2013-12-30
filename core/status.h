#include <gtk/gtk.h>
#include <gtksourceview/gtksource.h>

void on_query_data(GtkSourceGutterRenderer *renderer, GtkTextIter *start, GtkTextIter *end, GtkSourceGutterRendererState state, gpointer data) {
  GtkTextBuffer *buffer = gtk_text_view_get_buffer(data);
  if (!gtk_widget_is_focus(data)) {
    gtk_source_gutter_renderer_text_set_text((GtkSourceGutterRendererText*)renderer, "", -1);
    gtk_source_gutter_renderer_set_size(renderer, 0);
    return;
  }
  GtkTextIter it;
  gtk_text_buffer_get_iter_at_mark(buffer, &it, gtk_text_buffer_get_insert(buffer));
  gint current_line = gtk_text_iter_get_line(&it);
  gchar text[16];
  g_sprintf(text, "%d", ABS(gtk_text_iter_get_line(start) - current_line));
  gtk_source_gutter_renderer_text_set_text((GtkSourceGutterRendererText*)renderer, text, -1);
  gtk_source_gutter_renderer_set_size(renderer, 30);
}

void setup_relative_line_number(void* viewp) {
  GtkSourceView *view = viewp;
  GtkSourceGutter *gutter = gtk_source_view_get_gutter(view, GTK_TEXT_WINDOW_LEFT);
  GtkSourceGutterRenderer *renderer = gtk_source_gutter_renderer_text_new();
  gtk_source_gutter_renderer_set_alignment(renderer, 1, 1);
  g_signal_connect(renderer, "query-data", G_CALLBACK(on_query_data), viewp);
  gtk_source_gutter_insert(gutter, renderer, 0);
}
