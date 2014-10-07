decl('core_status_init')
function core_status_init(self)
  -- current line and column
  View.mix(function(view)
    -- relative line number
    setup_relative_line_number(view.native)
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
      local modified = ''
      if buffer.buf:get_modified() then
        modified = 'underline="double"'
      end
      if buffer == current_buffer then
        table.insert(markup, '<span foreground="lightgreen" ' .. modified .. '>'
          .. Path_base(buffer.filename) .. '</span>')
      else
        table.insert(markup, '<span ' .. modified .. '>' .. Path_base(buffer.filename) .. '</span>')
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
