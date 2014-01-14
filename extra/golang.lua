decl('extra_golang_init')
function extra_golang_init(self)
  -- setup
  self.connect_signal('language-detected', function(buffer)
    if buffer.lang_name ~= 'Go' then return end

    golang_setup_completion(buffer.completion_providers)

    -- indent setup
    buffer.indent_width = 1
    buffer.indent_char = '\t'

    -- snippets
    local function new_snippet(trigger, name, snippet, line_start)
      buffer.add_snippet(name, snippet)
      local predicts = {function() return true end}
      if line_start then
        predicts = {self.starts_line_p}
      end
      buffer.add_pattern(trigger, function() buffer.insert_snippet(name) end,
        true, true, predicts)
    end

    new_snippet('f/', 'go_func', {'func$1($2) $3{', '$>$4', '$<}$5'})
    new_snippet('r/', 'go_for_range', {'for $1, $2 := range $3 {', '$>$4', '$<}$5'}, true)
    new_snippet('n/', 'go_fmt_printf', {'fmt.Printf("$1", $2)$3'}, true)
    new_snippet('g/', 'go_go_func', {'go func($1) {', '$>$2', '$<}($3)$4'})

  end)

  -- gofmt

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

  -- goimports

  local function imports(buffer)
    if buffer.lang_name ~= 'Go' then return end
    local buf = buffer.buf
    local out, err = goimports(buf:get_text(buf:get_start_iter(), buf:get_end_iter(), false))
    local view = self.get_current_view()
    if err ~= '' then -- error
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

  self.bind_command_key(',,f', function(args)
    --format(args.buffer)
    imports(args.buffer)
  end)

end
