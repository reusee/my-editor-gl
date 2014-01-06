decl('core_bookmark_init')
function core_bookmark_init(self)
  Buffer.mix(function(self)
    self.bookmarks = {}
  end)

  self.bind_command_key('b', function()
    return function(args)
      local keyval = args.keyval
      if not (keyval >= 0x20 and keyval <= 0x7e) then return end
      local buf = args.buffer.buf
      local buffer = args.buffer
      local mark = buf:create_mark(nil, buf:get_iter_at_mark(buf:get_insert()), true)
      if index_of(keyval, buffer.bookmarks) then
        buf:delete_mark(buffer.bookmarks[keyval]) end
      buffer.bookmarks[keyval] = mark
      self.show_message('mark ' .. chr(keyval))
    end
  end, 'create bookmark')

  self.bind_command_key("'", function()
    return function(args)
      local keyval = args.keyval
      if not (keyval >= 0x20 and keyval <= 0x7e) then return end
      local buffer = args.buffer
      local buf = buffer.buf
      local mark = buffer.bookmarks[keyval]
      if mark then buf:place_cursor(buf:get_iter_at_mark(mark)) end
      args.view.widget:scroll_to_mark(buf:get_insert(), 0, true, 1, 0.5)
    end
  end, 'jump to bookmark')

  Buffer.mix(function(buffer)
    buffer.edit_marks = {}
    buffer.edit_marks_index = 0
  end)
  self.connect_signal('entered-edit-mode', function(buffer)
    local buf = buffer.buf
    local edit_marks = buffer.edit_marks
    local cursor_iter = buf:get_iter_at_mark(buf:get_insert())
    local current_line = cursor_iter:get_line()
    for i = 1, #edit_marks do
      local it = buf:get_iter_at_mark(edit_marks[i])
      if math.abs(it:get_line() - current_line) <= 2 then
        buf:move_mark(edit_marks[i], cursor_iter)
        return
      end
    end
    edit_marks[#edit_marks + 1] = buf:create_mark(nil, cursor_iter, true)
    if #edit_marks > 3 then
      table.remove(edit_marks, 1)
    end
  end)

  self.bind_command_key('"', function(args)
    local edit_marks = args.buffer.edit_marks
    if #edit_marks == 0 then return end
    local edit_marks_index = args.buffer.edit_marks_index
    edit_marks_index = edit_marks_index + 1
    if edit_marks_index > #edit_marks then edit_marks_index = 1 end
    local buf = args.buffer.buf
    buf:place_cursor(buf:get_iter_at_mark(edit_marks[edit_marks_index]))
    args.buffer.edit_marks_index = edit_marks_index
  end)
end
