decl('extra_golang_init')
function extra_golang_init(self)
  -- setup
  self.connect_signal('language-detected', function(buffer)
    if buffer.lang_name ~= 'Go' then return end

    golang_setup_completion(buffer.completion_providers)

    -- indent setup
    buffer.indent_width = 1
    buffer.indent_char = '\t'

  end)

  local function format(buffer)
    if buffer.lang_name ~= 'Go' then return end
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
      buf:begin_user_action()
      buf:set_text(out, -1)
      buf:end_user_action()
    end
  end

  --self.connect_signal('before-saving', function(buffer)
  --  format(buffer)
  --end)

  self.bind_command_key(',,f', function(args)
    format(args.buffer)
  end)
end
