decl('core_status_init')
function core_status_init(self)
  -- current line and column
  View.mix(function(view)
    view.on_draw(function(gview, cr)
      if not gview.is_focus then return end
      local rect = gview:get_allocation()
      local buf = self.gview_get_buffer(gview).buf
      local cursor_rect = gview:get_iter_location(buf:get_iter_at_mark(buf:get_insert()))

      if buf:get_modified() then
        cr:set_source_rgb(0, 0.3, 0.5)
      else
        cr:set_source_rgb(0, 0.5, 0)
      end
      if self.operation_mode == self.COMMAND then
        cr:set_line_width(2)
      else
        cr:set_line_width(4)
      end
      local x, y = gview:buffer_to_window_coords(Gtk.TextWindowType.WIDGET,
        cursor_rect.x, cursor_rect.y)
      cr:move_to(x, 0)
      cr:line_to(x, rect.height)
      cr:stroke()

      cr:set_line_width(1)
      cr:set_source_rgb(0.8, 0.8, 0.8)
      cr:move_to(0, y + cursor_rect.height)
      cr:line_to(rect.width, y + cursor_rect.height)
      cr:stroke()
    end)
  end)
end
