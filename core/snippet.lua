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
    local point_marks = {}
    local point_order = {}
    function buffer.insert_snippet(name)
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
      -- first insert point
      if #point_order > 0 then
        buf:place_cursor(buf:get_iter_at_mark(orig_mark))
        buffer.snippet_next_insert_point()
      end
      buf:delete_mark(orig_mark)
    end

    -- next insert point
    function buffer.snippet_next_insert_point()
      if #point_order == 0 then return end
      buffer.clear_selections()
      local marks = point_marks[point_order[1]]
      for i = 1, #marks do
        if i == 1 then
          buf:place_cursor(buf:get_iter_at_mark(marks[1]))
        else
          buffer.toggle_selection(buf:get_iter_at_mark(marks[i]))
        end
        buf:delete_mark(marks[i])
        marks[i] = nil
      end
      point_marks[point_order[1]] = nil
      table.remove(point_order, 1)
    end
  end)

  -- next insert point
  self.bind_edit_key({Gdk.KEY_Alt_R}, function(args)
    args.buffer.snippet_next_insert_point()
  end)
end
