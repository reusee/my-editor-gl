decl('core_key_init')
function core_key_init(self)
  self.EDIT, self.COMMAND = 1, 2

  self.operation_mode = self.COMMAND
  self.command_key_handler = {}
  self.edit_key_handler = {}

  self.define_signal('key-pressed')
  self.key_pressed_return_value = false

  self.define_signal('key-done')
  self.define_signal('key-prefix')
  self.define_signal('numeric-prefix')
  self.define_signal('key-handler-execute')

  self.define_signal('entered-edit-mode')
  self.define_signal('entered-command-mode')

  -- redraw
  self.connect_signal({'entered-edit-mode', 'entered-command-mode', 'key-done'}, function()
    self.emit_signal('should-redraw')
  end)

  self.n = 0
  self.delay_chars = {}
  self.delay_chars_timer = false

  -- setup Buffer
  Buffer.mix(function(self)
    self.command_key_handler = {}
    self.edit_key_handler = {}
    self.key_handler = {}
  end)

  self.connect_signal('buffer-created', function(buffer)
    buffer.command_key_handler = self.copy_keymap(self.command_key_handler)
    buffer.edit_key_handler = self.copy_keymap(self.edit_key_handler)
    buffer.key_handler = buffer.command_key_handler
  end)

  function self.handle_key(view, ev_or_keyval)
    -- get keyval
    local val
    if type(ev_or_keyval) == 'userdata' then -- gdk key event
      self.emit_signal('key-pressed', view, ev_or_keyval) --TODO copy this
      if self.key_pressed_return_value == true then
        self.key_pressed_return_value = false
        return true
      end
      val = ev_or_keyval.keyval
    else -- by feed_keys
      val = ev_or_keyval
    end
    -- skip some keys
    if Set{
      Gdk.KEY_Shift_L, Gdk.KEY_Shift_R,
      Gdk.KEY_Alt_L, Gdk.KEY_Alt_R,
      Gdk.KEY_Control_L, Gdk.KEY_Control_R,
      }.contains(val) then
      return false
    end
    -- buffer and view
    local buffer = self.gview_get_buffer(view)
    local view = self.gview_to_View(view)
    -- cancel command
    if val == Gdk.KEY_Escape then
      self.enter_command_mode(buffer)
      return true
    end
    -- find handler
    local is_edit_mode = self.operation_mode == self.EDIT
    local handler = nil
    if type(buffer.key_handler) == 'table' then -- a keymap
      local key
      if val >= 0x20 and val <= 0x7e then
        key = string.char(val)
      else
        key = val
      end
      handler = buffer.key_handler[key]
    elseif type(buffer.key_handler) == 'function' then -- a handler
      handler = buffer.key_handler
    end
    -- run handler
    if type(handler) == 'function' then -- call the handler
      if is_edit_mode then -- edit mode
        if self.delay_chars_timer then
          GLib.source_remove(self.delay_chars_timer)
          self.delay_chars_timer = false
        end
        buffer.key_handler = buffer.edit_key_handler
        self.delay_chars = {}
      else -- command mode
        buffer.key_handler = buffer.command_key_handler
      end
      local ret = handler{
        view = view,
        buffer = buffer,
        n = self.n,
        keyval = val,
        }
      if type(ret) == 'function' or type(ret) == 'table' then -- another handler
        buffer.key_handler = ret
        self.emit_signal('key-prefix', string.char(val))
      elseif ret == 'is_numeric_prefix' then -- a number prefix
        self.emit_signal('numeric-prefix', tonumber(string.char(val)))
      elseif ret == 'propagate' then -- pass to gtk handler
        return false
      else -- dry executed
        self.n = 0
        self.emit_signal('key-done')
      end
    elseif type(handler) == 'table' then -- a sub-keymap
      buffer.key_handler = handler
      if is_edit_mode then -- delay insert command prefix
        table.insert(self.delay_chars, string.char(val))
        self.delay_chars_timer = GLib.timeout_add(GLib.PRIORITY_DEFAULT,
          200, function() self.insert_delay_chars(view) end)
      end
      self.emit_signal('key-prefix', string.char(val))
    else -- no handler
      if is_edit_mode then -- edit mode
        if self.delay_chars_timer then -- stop timer
          GLib.source_remove(self.delay_chars_timer)
          self.delay_chars_timer = false
        end
        self.insert_delay_chars(view)
        buffer.key_handler = buffer.edit_key_handler
        return false
      else -- command mode
        self.show_message('no handler')
        buffer.key_handler = buffer.command_key_handler
      end
      self.emit_signal('key-done')
    end
    return true
  end

  function self.insert_delay_chars(view)
    local buffer = self.view_get_buffer(view)
    local buf = buffer.buf
    buf:begin_user_action()
    buf:insert(buf:get_iter_at_mark(buf:get_insert()),
      table.concat(self.delay_chars, ''), -1)
    buf:end_user_action()
    buffer.key_handler = buffer.edit_key_handler
    self.delay_chars = {}
    self.emit_signal('key-done')
    self.delay_chars_timer = false
  end

  function self.copy_keymap(keymap)
    local copy = {}
    for k, v in pairs(keymap) do
      if type(v) == 'table' then
        copy[k] = self.copy_keymap(v)
      else
        copy[k] = v
      end
    end
    return copy
  end

  function self.feed_keys(view, seq)
    for c in seq:gmatch('.') do
      self.handle_key(view.widget, string.byte(c))
    end
  end

  function self.bind_command_key(seq, handler, desc)
    self.bind_key_handler(self.command_key_handler, seq, handler, desc)
    for _, buf in pairs(self.buffers) do
      self.bind_key_handler(buf.command_key_handler, seq, handler, desc)
    end
  end

  function self.bind_edit_key(seq, handler, desc)
    self.bind_key_handler(self.edit_key_handler, seq, handler, desc)
    for _, buf in pairs(self.buffers) do
      self.bind_key_handler(buf.edit_key_handler, seq, handler, desc)
    end
  end

  self.handler_description = {}
  function self.bind_key_handler(keymap, seq, handler, desc)
    self.handler_description[handler] = desc
    if type(seq) == 'string' then
      local ss = {}
      for c in seq:gmatch('.') do
        table.insert(ss, c)
      end
      seq = ss
    end
    local key
    for i = 1, #seq - 1 do
      key = seq[i]
      if not keymap[key] then
        keymap[key] = {}
      end
      if type(keymap[key]) ~= 'table' then -- conflict
        error('key binding conflict ' .. table.concat(seq, ''))
      end
      keymap = keymap[key]
    end
    if keymap[seq[#seq]] then -- conflict
      error('key binding conflict ' .. table.concat(seq, ''))
    end
    keymap[seq[#seq]] = handler
  end

  function self.enter_edit_mode(buf)
    self.operation_mode = self.EDIT
    buf.key_handler = buf.edit_key_handler
    self.emit_signal('entered-edit-mode')
  end

  self.bind_command_key('i', function(args)
    self.enter_edit_mode(args.buffer)
  end, 'enter edit mode')

  for i = 0, 9 do
    self.bind_command_key(tostring(i), function(args)
      self.n = self.n * 10 + i
      return 'is_numeric_prefix'
    end, 'numeric prefix')
  end

  function self.enter_command_mode(buf)
    self.operation_mode = self.COMMAND
    buf.key_handler = buf.command_key_handler
    self.n = 0
    self.emit_signal('key-done')
    self.emit_signal('entered-command-mode')
  end

  self.bind_edit_key('kd', function(args)
    self.enter_command_mode(args.buffer)
  end, 'enter command mode')

  -- mode indicator
  self.edit_mode_indicator = self.create_overlay_label(
    Gtk.Align.END, Gtk.Align.CENTER)
  self.edit_mode_indicator:set_markup('<span font="24" foreground="lightgreen">EDITING</span>')
  self.connect_signal('entered-edit-mode', function()
    self.edit_mode_indicator:show()
  end)
  self.connect_signal('entered-command-mode', function()
    self.edit_mode_indicator:hide()
  end)

  -- command prefix indicator
  self.command_prefix_indicator = self.create_overlay_label(
    Gtk.Align.END, Gtk.Align.END)
  self.command_prefix = {}

  function self.update_command_prefix_indicator()
    if #self.command_prefix == 0 and self.n == 0 then
      self.command_prefix_indicator:hide()
      return
    end
    local text = table.concat(self.command_prefix, '')
    if self.n ~= 0 then
      text = tostring(self.n) .. text
    end
    self.command_prefix_indicator:set_markup(
      '<span font="24" foreground="lightgreen">' .. text .. '</span>')
    self.command_prefix_indicator:show()
  end

  self.connect_signal('key-done', function()
    self.command_prefix = {}
    self.update_command_prefix_indicator()
  end)
  self.connect_signal('key-prefix', function(c)
    table.insert(self.command_prefix, c)
    self.update_command_prefix_indicator()
  end)
  self.connect_signal('numeric-prefix', function()
    self.update_command_prefix_indicator()
  end)

end -- core_key_init
