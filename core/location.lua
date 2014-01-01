decl('Location')
decl('core_location_init')
function core_location_init(self)
  Location = class{function(location, filename, line, offset)
    location.filename = filename or false
    location.line = line or false
    location.offset = offset or false

    function location.jump()
      -- ensure buffer
      local buffer = false
      local buffers = self.buffers
      for i = 1, #buffers do
        if buffers[i].filename == filename then
          buffer = buffers[i]
          break
        end
      end
      if not buffer then
        buffer = self.create_buffer(filename)
      end
      if not buffer then
        self.show_message('invalid location, cannot find buffer ' .. filename)
      end
      -- switch or create view
      local stack = self.get_current_view().wrapper:get_parent()
      local view
      for _, wrapper in ipairs(stack:get_children()) do
        view = self.view_from_wrapper(wrapper)
        if view.buffer.filename == filename then -- switch
          goto forelse
        end
      end
      view = self.create_view(buffer) -- create
      stack:add_named(view.wrapper, buffer.filename)
      ::forelse::
      stack:set_visible_child(view.wrapper)
      view.widget:grab_focus()
      -- jump to position
      local buf = buffer.buf
      local it = buf:get_start_iter()
      it:set_line(line)
      it:set_line_offset(offset)
      buf:place_cursor(it)
    end
  end}

end
