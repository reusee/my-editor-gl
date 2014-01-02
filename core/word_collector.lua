decl('core_word_collector_init')
function core_word_collector_init(self)
  Buffer.mix(function(self)
    self.word_start = self.buf:create_mark(nil, self.buf:get_start_iter(), true)
    self.word_end = self.buf:create_mark(nil, self.buf:get_start_iter(), true)

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

    local last_word_tag = Gtk.TextTag{name = 'last-word', underline = 1}
    self.buf.tag_table:add(last_word_tag)
  end)

end
