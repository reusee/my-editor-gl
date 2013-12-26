decl('core_status_init')
function core_status_init(self)
  -- current line and column
  View.mix(function(view)
    view.on_draw(function(gview, cr)
      if not gview.is_focus then return end
      local rect = gview:get_allocation()
      local buffer = self.gview_get_buffer(gview)
      local buf = buffer.buf
      local cursor_rect = gview:get_iter_location(buf:get_iter_at_mark(buf:get_insert()))

      local set_source_rgb = cr.set_source_rgb
      local set_line_width = cr.set_line_width
      local move_to = cr.move_to
      local line_to = cr.line_to
      local stroke = cr.stroke

      -- column
      if buf:get_modified() then -- modified
        set_source_rgb(cr, 0.49, 0.63, 1)
      else -- normal
        set_source_rgb(cr, 0.5, 1, 0.46)
      end
      if self.operation_mode == self.COMMAND then
        set_line_width(cr, 1)
      else
        set_line_width(cr, 2)
      end
      local x, y = gview:buffer_to_window_coords(Gtk.TextWindowType.WIDGET,
        cursor_rect.x, cursor_rect.y)
      move_to(cr, x, 0)
      line_to(cr, x, rect.height)
      stroke(cr)

      -- row
      set_line_width(cr, 1)
      if #buffer.selections > 0 then -- has selection
        set_source_rgb(cr, 0.49, 0.63, 1)
      else -- normal
        set_source_rgb(cr, 0.5, 1, 0.46)
      end
      move_to(cr, 0, y + cursor_rect.height)
      line_to(cr, rect.width, y + cursor_rect.height)
      stroke(cr)

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
      update_buffer_list(view.buffer)
    end)
    view.on_grab_focus(function()
      update_buffer_list(view.buffer)
    end)
  end)

end
