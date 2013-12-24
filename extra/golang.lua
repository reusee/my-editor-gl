decl('extra_golang_init')
function extra_golang_init(self)
  -- setup
  self.connect_signal('language-detected', function(buffer)
    if buffer.lang:get_name() ~= 'Go' then return end

    -- gocode completion provider
    local last_provided = Vocabulary()
    table.insert(buffer.completion_providers, function(buffer, input, candidates)
      local buf = buffer.buf
      if input == '' then
        local it = buf:get_iter_at_mark(buf:get_insert())
        if it:backward_char() then
          if tochar(it:get_char()) ~= '.' then return end
        end
      end
      local char_offset = buf:get_iter_at_mark(buf:get_insert()):get_offset()
      local ret = get_gocode_completions(buffer.filename, char_offset, buf:get_text(
        buf:get_start_iter(), buf:get_end_iter(), false))
      if #ret == 0 then -- no candidates, use last provided
        last_provided.each(function(word)
          if self.completion_fuzzy_match(word.text, input) then
            candidates.add(word)
          end
        end)
        do return end
      end
      last_provided.clear()
      for _, entry in ipairs(ret) do
        local word = {
          text = entry[1],
          source = 'Go',
          desc = entry[2],
        }
        candidates.add(word)
        last_provided.add(word)
      end
    end)

  end)

  self.connect_signal('before-saving', function(buffer)
    if buffer.lang:get_name() ~= 'Go' then return end
    local buf = buffer.buf
    local out, err = gofmt(buf:get_text(buf:get_start_iter(), buf:get_end_iter(), false))
    local view = self.get_current_view()
    if err ~= '' then -- error occured
      self.show_message(err)
      local line, col = string.match(err, '(%d+):(%d+):')
      local it = buf:get_start_iter()
      it:set_line(tonumber(line) - 1)
      it:set_line_index(tonumber(col) - 1)
      buf:place_cursor(it)
      view.widget:scroll_to_mark(buf:get_insert(), 0, false, 0, 0)
    else
      view.save_scroll_state()
      buf:set_text(out, -1)
      view.restore_scroll_state()
    end
  end)
end