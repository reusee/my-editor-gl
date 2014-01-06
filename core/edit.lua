decl('core_edit_init')
function core_edit_init(self)
  -- clipboard
  self.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
  self.extra_clipboard = {}

  -- paste
  self.bind_command_key('p', function(args)
    local buf = args.buffer.buf
    local buffer = args.buffer
    local n = args.n
    if n == 0 then n = 1 end
    for i = 1, n do
      buf:paste_clipboard(self.clipboard, nil, true)
    end
    buf:begin_user_action()
    for i = 1, #self.extra_clipboard do
      local sel = buffer.selections[i]
      if not sel then break end
      local start_iter = buf:get_iter_at_mark(sel.start)
      local stop_iter = buf:get_iter_at_mark(sel.stop)
      buf:delete(start_iter, stop_iter)
      for _ = 1, n do
        buf:insert(start_iter, self.extra_clipboard[i], -1)
      end
    end
    buf:end_user_action()
    buffer.clear_selections()
  end, 'paste')
  self.bind_command_key(',p', function(args)
    local buf = args.buffer.buf
    local it = buf:get_iter_at_mark(buf:get_insert())
    it:forward_line()
    buf:paste_clipboard(self.clipboard, it, true)
  end, 'paste to next line')

  -- undo and redo
  self.bind_command_key('u', function(args)
    local buf = args.buffer.buf
    if buf.can_undo then
      buf:undo()
      buf:place_cursor(buf:get_iter_at_mark(buf:get_insert()))
      args.view.widget:scroll_to_mark(buf:get_insert(), 0, false, 0, 0)
    else
      self.show_message('no undo action')
    end
  end, 'undo')
  self.bind_command_key('Y', function(args)
    local buf = args.buffer.buf
    if buf.can_redo then
      buf:redo()
      buf:place_cursor(buf:get_iter_at_mark(buf:get_insert()))
      args.view.widget:scroll_to_mark(buf:get_insert(), 0, false, 0, 0)
    else
      self.show_message('no redo action')
    end
  end, 'redo')

  -- misc edit operations

  function self._get_current_line_indent_str(buf)
    local it = buf:get_iter_at_mark(buf:get_insert())
    it:set_line_offset(0)
    local start = it:copy()
    while not it:ends_line() and chr(it:get_char()):find('^%s$') do
      it:forward_char()
    end
    return buf:get_text(start, it, false)
  end

  -- new line
  self.bind_command_key('o', function(args)
    local buf = args.buffer.buf
    local indent_str = self._get_current_line_indent_str(buf)
    local it = buf:get_iter_at_mark(buf:get_insert())
    if not it:ends_line() then
      it:forward_to_line_end()
    end
    buf:begin_user_action()
    buf:insert(it, '\n' .. indent_str, -1)
    buf:end_user_action()
    buf:place_cursor(it)
    self.enter_edit_mode(args.buffer)
  end, 'insert new line below')
  self.bind_command_key('O', function(args)
    local buf = args.buffer.buf
    local indent_str = self._get_current_line_indent_str(buf)
    local it = buf:get_iter_at_mark(buf:get_insert())
    it:set_line_offset(0)
    buf:begin_user_action()
    buf:insert(it, '\n', -1)
    it:backward_line()
    buf:insert(it, indent_str, -1)
    buf:end_user_action()
    buf:place_cursor(it)
    self.enter_edit_mode(args.buffer)
  end, 'insert new line above')

  -- append
  self.bind_command_key('a', function(args)
    Transform({self.iter_jump_relative_char, 1}, {'iter'}, 'cursor').apply(args.buffer)
    self.enter_edit_mode(args.buffer)
  end, 'append after current char')
  self.bind_command_key('A', function(args) Transform(
    {self.iter_jump_to_line_end, 0},
    {'iter'}, 'cursor').apply(args.buffer)
    self.enter_edit_mode(args.buffer)
  end, 'append at line end')

  -- delete
  self.bind_command_key('x', function(args)
    local buf = args.buffer.buf
    local start = buf:get_iter_at_mark(buf:get_insert())
    local stop = start:copy()
    stop:forward_char()
    self.clipboard:set_text(buf:get_text(start, stop, false), -1)
    buf:begin_user_action()
    buf:delete(start, stop)
    buf:end_user_action()
  end, 'delete current char')

  -- insert
  self.bind_command_key('I', function(args)
    local buf = args.buffer.buf
    local it = buf:get_iter_at_mark(buf:get_insert())
    it:set_line_offset(0)
    while not it:ends_line() and chr(it:get_char()):find('^%s$') do
      it:forward_char()
    end
    buf:place_cursor(it)
    self.enter_edit_mode(args.buffer)
  end, 'insert at first non-space char')

  -- change line
  self.bind_command_key('C', function(args)
    local buf = args.buffer.buf
    local it = buf:get_iter_at_mark(buf:get_insert())
    it:set_line_offset(0)
    while not it:ends_line() and chr(it:get_char()):find('^%s$') do
      it:forward_char()
    end
    local line_end = it:copy()
    if not line_end:ends_line() then line_end:forward_to_line_end() end
    buf:begin_user_action()
    buf:delete(it, line_end)
    buf:end_user_action()
    buf:place_cursor(it)
    self.enter_edit_mode(args.buffer)
  end, 'change from first non-space char')

  -- backspace
  self.bind_edit_key({Gdk.KEY_BackSpace}, function(args)
    local buf = args.buffer.buf
    local it = buf:get_iter_at_mark(buf:get_insert())
    local stop = it:copy()
    local nonspace_deleted = false
    if it:backward_char() then
      local deleted_char = chr(it:get_char())
      if not deleted_char:find('^%s$') then
        nonspace_deleted = true
      end
      buf:begin_user_action()
      buf:delete(it, stop)
      buf:end_user_action()
    end
    if nonspace_deleted then return end
    local i = it:get_line_offset() % args.buffer.indent_width
    while i ~= 0 do
      if it:backward_char() and chr(it:get_char()):find('^%s$') then
        buf:begin_user_action()
        buf:delete(it, stop)
        buf:end_user_action()
        i = i - 1
      else
        break
      end
    end
  end, 'backspace with dedent')

  -- change quotation
  self.bind_command_key('mq', function(args1)
    return function(args2)
      local new = chr(args2.keyval)
      if not self.BRACKETS[new] then return end
      local buf = args2.buffer.buf
      local it = buf:get_iter_at_mark(buf:get_insert())
      local it2 = it:copy()
      self.iter_jump_to_matching_bracket(it2, args2.buffer)
      if it:compare(it2) == 0 then return end
      local m = buf:create_mark(nil, it2, true)
      buf:begin_user_action()
      local tmp_it = it:copy()
      tmp_it:forward_char()
      buf:delete(it, tmp_it)
      buf:insert(it, new, -1)
      it2 = buf:get_iter_at_mark(m)
      buf:delete_mark(m)
      tmp_it = it2:copy()
      tmp_it:forward_char()
      buf:delete(it2, tmp_it)
      buf:insert(it2, self.BRACKETS[new], -1)
      buf:end_user_action()
    end
  end, 'change quotation')

  -- macros

  self.bind_command_key('.j', function(args)
    self.feed_keys(args.view, 'b1' .. tostring(args.n) .. "ggdd'1,p")
  end, 'move line n to next line')

  self.bind_command_key('.k', function(args)
    self.feed_keys(args.view, 'b1dd' .. tostring(args.n) .. "ggp'1")
  end, 'move current line to line n')

  self.bind_command_key('.l', function(args)
    self.feed_keys(args.view, 'b1' .. tostring(args.n) .. "ggyy'1,p")
  end, 'copy line n to next line')

end -- core_edit_init
