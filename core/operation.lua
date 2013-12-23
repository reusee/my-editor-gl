decl('core_operation_init')
function core_operation_init(self)
  Buffer.mix(function(buffer)
    function buffer.delete_selection()
      local deleted = false
      local buf = buffer.buf
      buf:begin_user_action()
      for _, sel in ipairs(buffer.selections) do
        local start_iter = buf:get_iter_at_mark(sel.start)
        local stop_iter = buf:get_iter_at_mark(sel.stop)
        if start_iter:compare(stop_iter) ~= 0 then deleted = true end
        buf:delete(start_iter, stop_iter)
      end
      deleted = buf:delete_selection(true, true)
      buf:end_user_action()
      return deleted
    end

    function buffer.copy_selection()
      local has_selection = false
      local buf = buffer.buf
      if buf:get_has_selection() then
        buf:copy_clipboard(self.clipboard)
        has_selection = true
      end
      local number = 1
      for _, sel in ipairs(buffer.selections) do
        local start_iter = buf:get_iter_at_mark(sel.start)
        local stop_iter = buf:get_iter_at_mark(sel.stop)
        if start_iter:compare(stop_iter) == 0 then goto continue end
        has_selection = true
        self.extra_clipboard[number] = buf:get_text(start_iter, stop_iter, false)
        number = number + 1
        ::continue::
      end
      return has_selection
    end

    local function indent_selection(sel, indent_string)
      local buf = buffer.buf
      local start = buf:get_iter_at_mark(sel.start)
      local stop = buf:get_iter_at_mark(sel.stop)
      while start:compare(stop) < 0 do
        if not start:starts_line() then
          start:forward_line()
        end
        if start:compare(stop) >= 0 then break end
        buf:begin_user_action()
        buf:insert(start, indent_string, -1)
        buf:end_user_action()
        stop = buf:get_iter_at_mark(sel.stop)
      end
    end
    function buffer.indent_selection(indent_string)
      for _, sel in ipairs(buffer.selections) do
        indent_selection(sel, indent_string)
      end
      indent_selection(buffer.cursor, indent_string)
    end

    local function dedent_selection(sel, dedent_level)
      local buf = buffer.buf
      local start = buf:get_iter_at_mark(sel.start)
      local stop = buf:get_iter_at_mark(sel.stop)
      if not start:starts_line() then start:forward_line() end
      while start:compare(stop) < 0 do
        local it = start:copy()
        while tochar(it:get_char()):isspace() and it:get_line_offset() < dedent_level do
          it:forward_char()
        end
        if it:get_line_offset() <= dedent_level then
          buf:begin_user_action()
          buf:delete(start, it)
          buf:end_user_action()
        end
        start:forward_line()
        stop = buf:get_iter_at_mark(sel.stop)
      end
    end
    function buffer.dedent_selection(dedent_level)
      for _, sel in ipairs(buffer.selections) do
        dedent_selection(sel, dedent_level)
      end
      dedent_selection(buffer.cursor, dedent_level)
    end
  end)

  self.bind_command_key('d', function(args)
    local buffer = args.buffer
    local func = function()
      if not buffer.copy_selection() then -- nothing is selected
        return false
      end
      buffer.delete_selection()
      buffer.clear_selections()
      return true
    end
    if not func() then
      buffer.delayed_selection_operation = func
      return self.selection_extend_subkeymap
    end
  end, 'delete selection')

  self.bind_command_key('c', function(args)
    local buffer = args.buffer
    local func = function()
      if not buffer.copy_selection() then -- nothing is selected
        return false
      end
      buffer.delete_selection()
      self.enter_edit_mode(buffer)
      return true
    end
    if not func() then
      buffer.delayed_selection_operation = func
      return self.selection_extend_subkeymap
    end
  end, 'change selection')

  self.bind_command_key('y', function(args)
    local buffer = args.buffer
    local func = function()
      if not buffer.copy_selection() then -- nothing is selected
        return false
      end
      buffer.clear_selections()
      return true
    end
    if not func() then
      buffer.delayed_selection_operation = func
      return self.selection_extend_subkeymap
    end
  end, 'copy selection')

  self.bind_command_key(',>', function(args)
    local buf = args.buffer.buf
    local gview = args.view.widget
    local indent_string = (' '):rep(gview:get_indent_width() * args.n)
    if not buf:get_has_selection() then -- select current line
      local it = buf:get_iter_at_mark(buf:get_insert())
      if not it:starts_line() then it:set_line_offset(0) end
      buf:move_mark(buf:get_selection_bound(), it)
      if not it:ends_line() then it:forward_to_line_end() end
      buf:move_mark(buf:get_insert(), it)
    end
    args.buffer.indent_selection(indent_string)
    args.buffer.clear_selections()
  end, 'indent selection')

  self.bind_command_key(',<', function(args)
    local buf = args.buffer.buf
    local gview = args.view.widget
    local dedent_level = gview:get_indent_width() * args.n
    if not buf:get_has_selection() then -- select current line
      local it = buf:get_iter_at_mark(buf:get_insert())
      if not it:starts_line() then it:set_line_offset(0) end
      buf:move_mark(buf:get_selection_bound(), it)
      if not it:ends_line() then it:forward_to_line_end() end
      buf:move_mark(buf:get_insert(), it)
    end
    args.buffer.dedent_selection(dedent_level)
    args.buffer.clear_selections()
  end, 'dedent selection')
end
