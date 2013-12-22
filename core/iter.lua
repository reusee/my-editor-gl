decl('core_iter_init')
function core_iter_init(self)
  function self.iter_jump_relative_line_with_preferred_offset(it, buffer, n, backward)
    if backward then
      for _ = 1, n do it:backward_line() end
    else
      for _ = 1, n do it:forward_line() end
    end
    local chars_in_line = it:get_chars_in_line() - 1 -- exclude newline
    local offset = buffer.preferred_line_offset
    if offset > chars_in_line then offset = chars_in_line end
    if offset >= 0 then it:set_line_offset(offset) end
  end

  function self.iter_jump_relative_char(it, buffer, n, backward)
    if backward then
      for _ = 1, n do it:backward_char() end
    else
      for _ = 1, n do it:forward_char() end
    end
  end

  function self.iter_jump_to_string(it, buffer, n, s, backward)
    for _ = 1, n do
      if backward then
        local res = it:backward_search(s, 0, buffer.buf:get_start_iter())
        if res then it:set_offset(res:get_offset())
        else break end
      else
        local pin = it:copy()
        pin:forward_char()
        local res = pin:forward_search(s, 0, buffer.buf:get_end_iter())
        if res then it:set_offset(res:get_offset())
        else break end
      end
    end
  end

  function self.iter_jump_to_line_n(it, buffer, n)
    it:set_line(n - 1)
  end

  function self.iter_jump_to_line_start_or_nonspace_char(it, buffer, n)
    if it:starts_line() then
      while tochar(it:get_char()):isspace() and not it:ends_line() do
        it:forward_char()
      end
    else
      it:set_line_offset(0)
    end
  end

  function self.iter_jump_to_first_nonspace_char(it, buffer, n)
    it:set_line_offset(0)
    while tochar(it:get_char()):isspace() and not it:ends_line() do
      it:forward_char()
    end
  end

  function self.iter_jump_to_line_end(it, buffer, n)
    if not it:ends_line() then it:forward_to_line_end() end
  end

  function self.iter_jump_to_line_start(it, buffer, n, backward)
    if not it:starts_line() then it:set_line_offset(0) end
    for _ = 1, n - 1 do
      if backward then it:backward_line()
      else it:forward_line() end
    end
  end

  function self.iter_jump_to_empty_line(it, buffer, n, backward)
    local f
    if backward then f = function() return it:backward_line() end
    else f = function() return it:forward_line() end end
    local ret
    while n > 0 do
      ret = f()
      while ret and it:get_bytes_in_line() ~= 1 do
        ret = f()
      end
      n = n - 1
    end
  end

  function self.iter_jump_to_matching_bracket(iter, buffer)
    local it = iter:copy()
    local start = tochar(it:get_char())
    local is_left = false
    local match = false
    for left, right in pairs(self.BRACKETS) do
      if left == right then goto continue end
      if left == start then
        is_left = true
        match = right
        break
      elseif right == start then
        match = left
        break
      end
    ::continue::
    end
    if not match then it:backward_char() end

    start = tochar(it:get_char())
    is_left = false
    match = false
    for left, right in pairs(self.BRACKETS) do
      if left == right then goto continue2 end
      if left == start then
        is_left = true
        match = right
        break
      elseif right == start then
        match = left
        break
      end
      ::continue2::
    end
    if not match then return end

    local balance = 0
    local found = false
    if is_left then it:forward_char()
    else it:backward_char() end
    local c
    while true do
      c = tochar(it:get_char())
      if c == match and balance == 0 then -- found
        found = true
        break
      elseif c == match then
        balance = balance - 1
      elseif c == start then
        balance = balance + 1
      end
      if is_left then
        if not it:forward_char() then break end
      else
        if not it:backward_char() then break end
      end
    end
    if not found then return end
    iter:set_offset(it:get_offset())
  end

  function self.iter_jump_to_word_edge(it, buffer, backward)
    if backward then it:backward_char() end
    local at_begin = false
    while buffer.is_word_char(tochar(it:get_char())) do
      if backward then
        if not it:backward_char() then
          at_begin = true
          break
        end
      else
        it:forward_char()
      end
    end
    if backward and not at_begin then it:forward_char() end
  end

  --TODO mark_jump_to_indent_block_edge
  --TODO iter_get_indent_level

  -- update preferred_line_offset
  Buffer.mix(function(buffer)
    buffer.on_cursor_position(function()
      if buffer.current_transform and self.operation_mode == self.COMMAND then
        if buffer.current_transform.start_func == self.iter_jump_relative_line_with_preferred_offset then
          do return end
        end
      end
      buffer.preferred_line_offset = buffer.buf:get_iter_at_mark(
        buffer.buf:get_insert()):get_line_offset()
    end)
  end)
end
