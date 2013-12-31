decl('core_word_collector_init')
function core_word_collector_init(self)
  Buffer.mix(function(self)
    self.word_start = self.buf:create_mark(nil, self.buf:get_start_iter(), true)
    self.word_end = self.buf:create_mark(nil, self.buf:get_end_iter(), true)
    self.define_signal('found-word')

    function self.word_start_iter_extend(start_iter)
      local it = start_iter:copy()
      while it:backward_char() do
        if self.is_word_char(tochar(it:get_char())) then
          start_iter:backward_char()
        else
          break
        end
      end
      return start_iter
    end

    function self.word_end_iter_extend(end_iter, limit_iter)
      local word_ended = false
      while end_iter:compare(limit_iter) < 0 do
        if self.is_word_char(tochar(end_iter:get_char())) then
          end_iter:forward_char()
        else
          word_ended = true
          break
        end
      end
      return end_iter, word_ended
    end
  end)

  self.connect_signal('buffer-created', function(buffer)
    local buf = buffer.buf
    buffer.on_changed(function()
      if self.operation_mode ~= self.EDIT then return end
      local start_iter = buf:get_iter_at_mark(buffer.word_start)
      local end_iter = buf:get_iter_at_mark(buffer.word_end)
      local cursor_iter = buf:get_iter_at_mark(buf:get_insert())
      start_iter = buffer.word_start_iter_extend(start_iter)
      local word_ended
      end_iter, word_ended = buffer.word_end_iter_extend(end_iter, cursor_iter)
      if word_ended or start_iter:compare(end_iter) == 0 then -- reset start and end
        if start_iter:compare(end_iter) < 0 then
          buffer.emit_signal('found-word', buf:get_text(start_iter, end_iter, false))
        end
        buf:move_mark(buffer.word_start, cursor_iter)
        buf:move_mark(buffer.word_end, cursor_iter)
      else
        buf:move_mark(buffer.word_start, start_iter)
        buf:move_mark(buffer.word_end, end_iter)
      end
    end)

    -- collect words
    local text = buf:get_text(buf:get_start_iter(), buf:get_end_iter(), false)
    local words = regexfindall(buffer.word_regex, text)
    each(function(word) buffer.emit_signal('found-word', word) end, words)
  end)

  self.connect_signal('entered-edit-mode', function(buffer)
    local buf = buffer.buf
    local start_iter = buf:get_iter_at_mark(buf:get_insert())
    local end_iter = start_iter:copy()
    start_iter = buffer.word_start_iter_extend(start_iter)
    buf:move_mark(buffer.word_start, start_iter)
    buf:move_mark(buffer.word_end, end_iter)
  end)
  self.connect_signal('entered-command-mode', function(buffer)
    local buf = buffer.buf
    local start_iter = buf:get_iter_at_mark(buffer.word_start)
    local end_iter = buf:get_iter_at_mark(buffer.word_end)
    end_iter, _ = buffer.word_end_iter_extend(end_iter, buf:get_end_iter())
    if start_iter:compare(end_iter) < 0 then
      buffer.emit_signal('found-word', buf:get_text(start_iter, end_iter, false))
    end
  end)
end
