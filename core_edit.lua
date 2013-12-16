decl('core_edit_init')
function core_edit_init(self)
  -- clipboard
  self.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
  self.extra_clipboard = {}

  -- paste
  self.bind_command_key('p', function(args)
    local buf = args.buffer.buf
    local n = args.n
    if n == 0 then n = 1 end
    for i = 1, n do
      buf:paste_clipboard(self.clipboard, nil, true)
    end
    --TODO multiple selections
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
      --TODO show message
    end
  end, 'undo')
  self.bind_command_key('Y', function(args)
    local buf = args.buffer.buf
    if buf.can_redo then
      buf:redo()
      buf:place_cursor(buf:get_iter_at_mark(buf:get_insert()))
      args.view.widget:scroll_to_mark(buf:get_insert(), 0, false, 0, 0)
    else
      --TODO show message
    end
  end, 'redo')

  -- misc edit operations

  function self._get_current_line_indent_str(buf)
    local it = buf:get_iter_at_mark(buf:get_insert())
    it:set_line_offset(0)
    local start = it:copy()
    while not it:ends_line() and string.find(string.char(it:get_char()), '^%s$') do
      it:forward_char()
    end
    return buf:get_text(start, it, false)
  end

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

  --TODO append current pos
  --TODO append current line

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

  self.bind_command_key('I', function(args)
    local buf = args.buffer.buf
    local it = buf:get_iter_at_mark(buf:get_insert())
    it:set_line_offset(0)
    while not it:ends_line() and string.find(string.char(it:get_char()), '^%s$') do
      it:forward_char()
    end
    buf:place_cursor(it)
    self.enter_edit_mode(args.buffer)
  end, 'insert at first non-space char')

  self.bind_command_key('C', function(args)
    local buf = args.buffer.buf
    local it = buf:get_iter_at_mark(buf:get_insert())
    it:set_line_offset(0)
    while not it:ends_line() and string.find(string.char(it:get_char()), '^%s$') do
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

  self.bind_edit_key({Gdk.KEY_BackSpace}, function(args)
    local buf = args.buffer.buf
    local it = buf:get_iter_at_mark(buf:get_insert())
    local stop = it:copy()
    local nonspace_deleted = false
    if it:backward_char() then
      local deleted_char = string.char(it:get_char())
      if not string.find(deleted_char, '^%s$') then
        nonspace_deleted = true
      end
      buf:begin_user_action()
      buf:delete(it, stop)
      buf:end_user_action()
    end
    if nonspace_deleted then return end
    local i = it:get_line_offset() % args.buffer.indent_width
    while i ~= 0 do
      if it:backward_char() and string.find(string.char(it:get_char()), '^%s$') then
        buf:begin_user_action()
        buf:delete(it, stop)
        buf:end_user_action()
        i = i - 1
      else
        break
      end
    end
  end, 'backspace with dedent')

  -- macros

  --TODO not working
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
