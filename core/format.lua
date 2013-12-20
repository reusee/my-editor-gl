decl('core_format_init')
function core_format_init(self)
  -- strip trailing whitespace
  self.connect_signal('before-saving', function(buffer)
    local buf = buffer.buf
    for l = 0, buf:get_line_count() - 1 do
      local start = buf:get_iter_at_line(l)
      local stop = start:copy()
      if not stop:ends_line() then stop:forward_to_line_end() end
      local eol = stop:copy()
      while stop:compare(start) == 1 do
        stop:backward_char()
        if not tochar(stop:get_char()):find('^%s$') then
          stop:forward_char()
          break
        end
      end
      buf:begin_user_action()
      buf:delete(stop, eol)
      buf:end_user_action()
    end
  end)

  -- ensure last char is a newline
  self.connect_signal('before-saving', function(buffer)
    local buf = buffer.buf
    local it = buf:get_end_iter()
    if not it:backward_char() then return end
    if tochar(it:get_char()) ~= '\n' then
      buf:begin_user_action()
      buf:insert(buf:get_end_iter(), '\n', -1)
      buf:end_user_action()
    end
  end)
end
