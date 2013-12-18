decl('core_search_init')
function core_search_init(self)
  Buffer.mix(function(self)
    self.search_pattern = ''
    self.search_range_start = self.buf:create_mark(nil, self.buf:get_start_iter(), true)
    self.search_range_end = self.buf:create_mark(nil, self.buf:get_end_iter(), true)
    self.search_result_tag = Gtk.TextTag{name = 'search-result', background = '#002b36', foreground = '#FFFF00'}
    self.buf.tag_table:add(self.search_result_tag)
    function self.update_search_result()
      local pattern = self.search_pattern
      if pattern == '' then return end
      local buf = self.buf
      buf:remove_tag(self.search_result_tag, buf:get_start_iter(), buf:get_end_iter())
      local content = buf:get_slice(
        buf:get_iter_at_mark(self.search_range_start), buf:get_iter_at_mark(self.search_range_end), false)
      local offset = buf:get_iter_at_mark(self.search_range_start):get_offset()
      local indexes = regexindex(pattern, content)
      if not indexes then return end
      local start = buf:get_start_iter()
      local stop = start:copy()
      for _, match in ipairs(indexes) do
        start:set_offset(offset + match[1])
        stop:set_offset(offset + match[2])
        buf:apply_tag(self.search_result_tag, start, stop)
      end
    end
    self.on_changed(self.update_search_result)
  end)

  local search_entry = SearchEntry(self)
  self.south_area:add(search_entry.widget)
  self.on_realize(function() search_entry.widget:hide() end)

  search_entry.connect_signal('update', function(view)
    local buffer = self.view_get_buffer(view)
    local buf = buffer.buf
    buffer.update_search_result()
    local it = buf:get_iter_at_mark(buf:get_insert())
    local res
    if search_entry.is_backward then
      res = it:backward_to_tag_toggle(buffer.search_result_tag)
    else
      res = it:forward_to_tag_toggle(buffer.search_result_tag)
    end
    if res then
      view.widget:scroll_to_iter(it, 0, true, 1, 0.5)
    end
  end)

  self.bind_command_key('/', function(args)
    search_entry.run(args.view)
  end, 'search forward')
  self.bind_command_key('?', function(args)
    search_entry.run(args.view, true)
  end, 'search backward')

  local function next_search_result(view, backward)
    if backward == nil then backward = false end
    local buffer = self.view_get_buffer(view)
    local buf = buffer.buf
    local it = buf:get_iter_at_mark(buf:get_insert())
    local func = function(tag) return it:forward_to_tag_toggle(tag) end
    if backward then func = function(tag) return it:backward_to_tag_toggle(tag) end end
    local tag = buffer.search_result_tag
    if func(tag) then
      if it:ends_tag(tag) then
        if func(tag) then buf:place_cursor(it)
        else self.show_message('no more search result') end
      else
        buf:place_cursor(it)
      end
    else
      self.show_message('no more search result')
    end
    view.widget:scroll_to_mark(buf:get_insert(), 0, false, 0, 0)
  end
  search_entry.connect_signal('done', function(view)
    next_search_result(view, search_entry.is_backward)
  end)
  self.bind_command_key('n', function(args)
    next_search_result(args.view)
  end, 'next search result')
  self.bind_command_key('N', function(args)
    next_search_result(args.view, true)
  end, 'previous search result')

  --TODO search current word
end

decl('SearchEntry')
SearchEntry = class{
  core_signal_init,
  function(self, editor)
    self.editor = editor

    self.define_signal('done')
    self.define_signal('update')

    local is_backward = false
    local view = false
    local history = {}
    local history_index = 1

    local function update()
      self.editor.view_get_buffer(view).search_pattern = self.widget:get_text()
      self.emit_signal('update', view)
    end

    self.widget = Gtk.Entry{hexpand = true}
    self.widget:set_alignment(0.5)
    self.widget.on_notify:connect(function() update() end, 'text')
    self.widget.on_key_press_event:connect(function(_, event)
      if event.keyval == Gdk.KEY_Escape or event.keyval == Gdk.KEY_Return then
        if event.keyval == Gdk.KEY_Escape then -- cancel
          view.widget:scroll_to_mark(
            self.editor.view_get_buffer(view).buf:get_insert(),
            0, true, 1, 0.5)
        else -- Enter
          update()
          local text = self.widget:get_text()
          if text ~= "" then table.insert(history, 1, text) end
          self.emit_signal('done', view)
        end
        self.widget:hide()
        view.widget:grab_focus()
      elseif event.keyval == Gdk.KEY_Tab then -- cycle history
        if #history == 0 then return end
        self.widget:set_text(history[history_index])
        history_index = history_index + 1
        if history_index > #history then history_index = 1 end
        return true
      end
    end)

    function self.run(v, backward)
      if backward == nil then backward = false end
      local buffer = self.editor.view_get_buffer(v)
      local buf = buffer.buf
      if buf:get_has_selection() then -- search inside selection
        local start, stop = buf:get_selection_bounds()
        buf:move_mark(buffer.search_range_start, start)
        buf:move_mark(buffer.search_range_end, stop)
        --TODO clear selections
      else
        buf:move_mark(buffer.search_range_start, buf:get_start_iter())
        buf:move_mark(buffer.search_range_end, buf:get_end_iter())
      end
      view = v
      is_backward = backward
      history_index = 1
      self.widget:show_all()
      self.widget:grab_focus()
    end
  end,
}
