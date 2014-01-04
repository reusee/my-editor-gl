decl('core_pattern_init')
function core_pattern_init(self)
  Buffer.mix(function(buffer)
    buffer.patterns = {}
    buffer.pattern_states = {}

    function buffer.add_pattern(pattern, callback, drop_key_event, clear_matched_text, predict)
      local path = pattern
      if type(pattern) == 'string' then -- convert to sequence
        path = {}
        pattern:each(function(e) table.insert(path, e) end)
      end
      local cur = buffer.patterns
      for i = 1, #path - 1 do
        local c = path[i]
        if not cur[c] then -- create path
          cur[c] = {}
          cur = cur[c]
        elseif type(cur[c]) ~= 'table' then -- conflict
          error('pattern conflict ' .. pattern)
        else -- path
          cur = cur[c]
        end
      end
      local key = path[#path]
      if cur[key] then -- conflict
        error('pattern conflict ' .. pattern)
      end
      cur[key] = {
        is_handler = true,
        pattern = pattern,
        predict = predict,
        callback = callback,
        drop_key_event = drop_key_event,
        clear_matched_text = clear_matched_text,
      }
    end

    buffer.add_pattern('foobar',
      function() self.show_message('foobar') end,
      false, false, function() return true end)
  end)

  self.connect_signal('key-pressed', function(gview, ev)
    if self.operation_mode ~= self.EDIT then return end
    local buffer = self.gview_get_buffer(gview)
    local c = chr(ev.keyval)
    local new_states = {}
    if #buffer.pattern_states == 0 then
      buffer.pattern_states[#buffer.pattern_states + 1] = buffer.patterns
    end
    for _, state in ipairs(buffer.pattern_states) do
      if not state[c] then goto continue end
      state = state[c]
      if not state.is_handler then -- not matched
        table.insert(new_states, state)
        goto continue
      end
      -- pattern matched
      if state.predict and not state.predict(buffer, state) then -- predict failed
        buffer.pattern_states = {}
        return
      end
      local buf = buffer.buf
      buf:begin_user_action()
      if state.clear_matched_text then
        local it = buf:get_iter_at_mark(buf:get_insert())
        local stop = it:copy()
        for _ = 1, #state.pattern - 1 do it:backward_char() end
        buf:delete(it, stop)
      end
      state.callback(buffer)
      if state.drop_key_event then
        self.key_pressed_return_value = true
      end
      buffer.pattern_states = {}
      buf:end_user_action()
      do return end
      ::continue::
    end
    local patterns = buffer.patterns
    if patterns[c] then
      table.insert(new_states, patterns[c])
    end
    buffer.pattern_states = new_states
  end)

  self.connect_signal('entered-command-mode', function()
    for _, buffer in ipairs(self.buffers) do
      if #buffer.pattern_states > 0 then
        buffer.pattern_states = {}
      end
    end
  end)

  function self.pattern_predict_cursor_at_line_start(buffer, state)
    local buf = buffer.buf
    local it = buf:get_iter_at_mark(buf:get_insert())
    for _ = 1, #state.pattern - 1 do
      it:backward_char()
    end
    local start = it:copy()
    start:set_line_offset(0)
    while not start:ends_line() and chr(start:get_char()):isspace() do
      start:forward_char()
    end
    return start:compare(it) == 0
  end
end
