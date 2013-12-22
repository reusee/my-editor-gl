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

  -- buffer list
  local buffer_list = Gtk.Label()
  self.south_area:add(buffer_list)
  buffer_list:set_hexpand(true)
  buffer_list:set_line_wrap(true)
  buffer_list:show_all()
  local function update_buffer_list(current_buffer)
    local markup = {}
    for _, buffer in ipairs(self.buffers) do
      if buffer == current_buffer then
        table.insert(markup, '<span foreground="lightgreen">'
          .. basename(buffer.filename) .. '</span>')
      else
        table.insert(markup, '<span>' .. basename(buffer.filename) .. '</span>')
      end
    end
    buffer_list:set_markup(table.concat(markup, '   '))
  end
  View.mix(function(view)
    view.on_buffer_changed(function()
      update_buffer_list(self.view_get_buffer(view))
    end)
    view.on_grab_focus(function()
      update_buffer_list(self.view_get_buffer(view))
    end)
  end)

end
