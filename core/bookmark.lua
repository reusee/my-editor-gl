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
end
