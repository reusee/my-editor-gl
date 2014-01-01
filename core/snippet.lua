decl('core_snippet_init')
function core_snippet_init(self)
  Buffer.mix(function(buffer)
    local buf = buffer.buf
    local selections = buffer.selections

    local function insert_at_selections(text)
      local sel
      for i = 1, #selections do
        sel = selections[i]
        buf:insert(buf:get_iter_at_mark(sel.stop), text, -1)
      end
      buf:insert(buf:get_iter_at_mark(buf:get_insert()), text, -1)
    end

    -- add snippet
    local snippets = {}
    function buffer.add_snippet(name, lines)
      local snippet = {}
      snippets[name] = snippet
      -- parse
      for i = 1, #lines do
        if i > 1 then
          snippet[#snippet + 1] = {'newline'}
        end
        local line = lines[i]
        local chunks = split_snippet_line(line)
        for ci = 1, #chunks do
          local chunk_type = chunks[ci][1]
          local chunk_content = chunks[ci][2]
          if chunk_type == 'c' then -- control
            if chunk_content == '$>' then -- indent
              snippet[#snippet + 1] = {'indent'}
            elseif chunk_content == '$<' then -- dedent
              snippet[#snippet + 1] = {'dedent'}
            elseif chunk_content == '$=' then -- align last line
              snippet[#snippet + 1] = {'align'}
            else -- insert point
              snippet[#snippet + 1] = {'point', tonumber(chunk_content:sub(2, -1))}
            end
          elseif chunk_type == 'l' then -- literal
            snippet[#snippet + 1] = {'literal', chunk_content}
          else
            error('unknow chunk type ' .. chunk_type)
          end
        end
      end
      --[[
      for i = 1, #snippet do
        print(snippet[i][1], snippet[i][2])
      end
      print()
      --]]
    end

    -- insert snippet
    local point_stack = {}
    buffer.point_stack = point_stack
    function buffer.insert_snippet(name)
      local point_marks = {}
      local point_order = {}
      local orig_mark = buf:create_mark(nil, buf:get_iter_at_mark(buf:get_insert()), true)
      -- get indent_str
      local it = buf:get_iter_at_mark(buf:get_insert())
      it:set_line_offset(0)
      local start = it:copy()
      while not it:ends_line() and tochar(it:get_char()):isspace() do
        it:forward_char()
      end
      local indent_str = buf:get_text(start, it, false)
      -- insert
      local snippet = snippets[name]
      buf:begin_user_action()
      for i = 1, #snippet do
        local ty = snippet[i][1]
        local content = snippet[i][2]
        if ty == 'literal' then -- literal
          insert_at_selections(content)
        elseif ty == 'point' then -- insert pointer
          local mark = buf:create_mark(nil, buf:get_iter_at_mark(buf:get_insert()), true)
          if not point_marks[content] then
            point_marks[content] = {}
            point_order[#point_order + 1] = content
          end
          point_marks[content][#point_marks[content] + 1] = mark
        elseif ty == 'newline' then
          insert_at_selections('\n')
        elseif ty == 'indent' then
          indent_str = indent_str .. string.rep(buffer.indent_char, buffer.indent_width)
          insert_at_selections(indent_str)
        elseif ty == 'dedent' then
          indent_str = indent_str:sub(1, -(1 + buffer.indent_width))
          insert_at_selections(indent_str)
        else
          error('unknown chunk type ' .. ty)
        end
      end
      buf:end_user_action()
      point_stack[#point_stack + 1] = {point_marks, point_order}
      -- first insert point
      if #point_order > 0 then
        buf:place_cursor(buf:get_iter_at_mark(orig_mark))
        buffer.snippet_next_insert_point()
      end
      buf:delete_mark(orig_mark)
    end

    -- next insert point
    function buffer.snippet_next_insert_point()
      if #point_stack == 0 then return end
      local point_marks = point_stack[#point_stack][1]
      local point_order = point_stack[#point_stack][2]
      buffer.clear_selections()
      local marks = point_marks[point_order[1]]
      for i = 1, #marks do
        if i == 1 then
          -- collect word
          local start_iter = buf:get_iter_at_mark(buf:get_insert())
          local end_iter = start_iter:copy()
          start_iter = buffer.word_start_iter_extend(start_iter)
          end_iter, _ = buffer.word_end_iter_extend(end_iter, buf:get_end_iter())
          buffer.emit_signal('found-word', buf:get_text(start_iter, end_iter, false))
          -- place cursor
          buf:place_cursor(buf:get_iter_at_mark(marks[1]))
          -- update word bounds and completion candidates
          start_iter = buffer.word_start_iter_extend(start_iter)
          end_iter, _ = buffer.word_end_iter_extend(end_iter, buf:get_end_iter())
          buf:move_mark(buffer.word_start, start_iter)
          buf:move_mark(buffer.word_end, end_iter)
          self.update_candidates(buffer)
        else
          buffer.toggle_selection(buf:get_iter_at_mark(marks[i]))
        end
        buf:delete_mark(marks[i])
        marks[i] = nil
      end
      point_marks[point_order[1]] = nil
      table.remove(point_order, 1)
      if #point_order == 0 then
        point_stack[#point_stack] = nil
      end
    end
  end)

  -- next insert point
  self.bind_edit_key({Gdk.KEY_Alt_R}, function(args)
    args.buffer.snippet_next_insert_point()
  end)

  -- clear point stack
  self.connect_signal('entered-command-mode', function(buffer)
    local point_stack = buffer.point_stack
    local buf = buffer.buf
    for i = 1, #point_stack do
      local point_marks = point_stack[i][1]
      local point_order = point_stack[i][2]
      for k = 1, #point_order do
        local key = point_order[k]
        for mi = 1, #point_marks[key] do
          buf:delete_mark(point_marks[key][mi])
          point_marks[key][mi] = nil
        end
        point_marks[key] = nil
      end
      point_stack[i] = nil
    end
  end)
end
