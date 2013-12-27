decl('core_transform_init')
function core_transform_init(self)
  Buffer.mix(function(buffer)
    buffer.current_transform = false
    buffer.last_transform = false
    buffer.define_signal('reset-relative-indicators')
    buffer.define_signal('set-relative-indicators')
    buffer.connect_signal('reset-relative-indicators', function()
      local view = self.get_current_view()
      hide_relative_indicators(view.relative_indicator_natives)
    end)
    local buf = buffer.buf
    local view
    buffer.connect_signal('set-relative-indicators', function(offsets)
      view = self.get_current_view()
      if #offsets > 0 then
        set_relative_indicators(buffer.native, view.native,
          offsets, view.relative_indicator_natives)
      end
    end)
  end)

  View.mix(function(view)
    view.relative_indicators = {}
    view.relative_indicator_natives = {}
    for i = 1, 50 do
      local label = Gtk.Label{
        use_markup = true,
        label = '<span font="8" foreground="red" background="black">' .. i .. '</span>',
        valign = Gtk.Align.START,
        halign = Gtk.Align.START,
      }
      view.overlay:add_overlay(label)
      view.relative_indicators[i] = label
      view.relative_indicator_natives[i] = label._native
      view.widget.on_realize:connect(function() label:hide() end)
    end
  end)

  self.bind_command_key(';', function(args)
      for i = 1, args.n do
        if i ~= args.n then
          args.buffer.last_transform.apply(args.buffer, true)
        else
          args.buffer.last_transform.apply(args.buffer)
        end
      end
    end, 'redo last transform')

  -- cursor moves
  self.bind_command_key('j', function(args) Transform(
    {self.iter_jump_relative_line_with_preferred_offset, args.n},
    {'iter'}, 'cursor').apply(args.buffer)
    end, 'relative forward line jump')
  self.bind_command_key('k', function(args) Transform(
    {self.iter_jump_relative_line_with_preferred_offset, args.n, true},
    {'iter'}, 'cursor').apply(args.buffer)
    end, 'relative backward line jump')
  self.bind_command_key('l', function(args) Transform(
    {self.iter_jump_relative_char, args.n},
    {'iter'}, 'cursor').apply(args.buffer)
    end, 'relative forward char jump')
  self.bind_command_key('h', function(args) Transform(
    {self.iter_jump_relative_char, args.n, true},
    {'iter'}, 'cursor').apply(args.buffer)
    end, 'relative backward char jump')
  self.bind_command_key('f', function() return function(args) Transform(
    {self.iter_jump_to_string, args.n, tochar(args.keyval)},
    {'iter'}, 'cursor').apply(args.buffer)
    end end, 'specified forward char jump')
  self.bind_command_key('mf', function() return function(args) Transform(
    {self.iter_jump_to_string, args.n, tochar(args.keyval), true},
    {'iter'}, 'cursor').apply(args.buffer)
    end end, 'specified backward char jump')
  self.bind_command_key('s', function(args) return function(args1) return function(args2)
    Transform({self.iter_jump_to_string, args.n, tochar(args1.keyval) .. tochar(args2.keyval)},
    {'iter'}, 'cursor').apply(args.buffer)
    end end end, 'specified forward two-chars jump')
  self.bind_command_key('ms', function(args) return function(args1) return function(args2)
    Transform({self.iter_jump_to_string, args.n, tochar(args1.keyval) .. tochar(args2.keyval), true},
    {'iter'}, 'cursor').apply(args.buffer)
    end end end, 'specified backward two-chars jump')
  self.bind_command_key('gg', function(args) Transform(
    {self.iter_jump_to_line_n, args.n},
    {'iter'}, 'cursor').apply(args.buffer)
    end, 'specified line jump')
  self.bind_command_key('G', function(args) Transform(
    {self.iter_jump_to_line_n, args.buffer.buf:get_line_count()},
    {'iter'}, 'cursor').apply(args.buffer)
    end, 'jump to end of buffer')
  self.bind_command_key('mr', function(args) Transform(
    {self.iter_jump_to_line_start_or_nonspace_char, args.n},
    {'iter'}, 'cursor').apply(args.buffer)
    end, 'jump to line start or first non-space char')
  self.bind_command_key('r', function(args) Transform(
    {self.iter_jump_to_line_end, 0},
    {'iter'}, 'cursor').apply(args.buffer)
    end, 'jump to line end')
  self.bind_command_key('[', function(args) Transform(
    {self.iter_jump_to_empty_line, args.n, true},
    {'iter'}, 'cursor').apply(args.buffer)
    end, 'jump to previous empty line')
  self.bind_command_key(']', function(args) Transform(
    {self.iter_jump_to_empty_line, args.n},
    {'iter'}, 'cursor').apply(args.buffer)
    end, 'jump to next empty line')
  self.bind_command_key('%', function(args) Transform(
    {self.iter_jump_to_matching_bracket},
    {'iter'}, 'cursor').apply(args.buffer)
    end, 'jump to matching bracket')

  self.bind_command_key('vj', function(args) Transform(
    {self.iter_jump_to_line_start, 1},
    {self.iter_jump_to_line_start, args.n + 1},
    'all').apply(args.buffer) end, 'relative forward line extend')
  self.alias_command_key('vd', 'vj')
  self.alias_command_key('vy', 'vj')
  self.bind_command_key('vk', function(args) Transform(
    {self.iter_jump_to_line_start, args.n, true},
    {self.iter_jump_to_line_start, 2},
    'all').apply(args.buffer) end, 'relative backward line extend')
  self.bind_command_key('vh', function(args) Transform(
    {self.iter_jump_relative_char, args.n, true},
    {false},
    'all').apply(args.buffer) end, 'relative backward char extend')
  self.bind_command_key('vl', function(args) Transform(
    {false},
    {self.iter_jump_relative_char, args.n},
    'all').apply(args.buffer) end, 'relative forward cha extend')
  self.bind_command_key('vf', function(args) return function(args2) Transform(
    {false},
    {self.iter_jump_to_string, args.n, tochar(args2.keyval)},
    'all').apply(args.buffer) end end, 'relative forward char extend')
  self.alias_command_key('vt', 'vf')
  self.bind_command_key('vmf', function(args) return function(args2) Transform(
    {self.iter_jump_to_string, args.n, tochar(args2.keyval), true},
    {false},
    'all').apply(args.buffer) end end, 'relative backward char extend')
  self.bind_command_key('vs', function(args) return function(args2) return function(args3) Transform(
    {false},
    {self.iter_jump_to_string, args.n, tochar(args2.keyval) .. tochar(args3.keyval)},
    'all').apply(args.buffer) end end end, 'specified forward two-chars extend')
  self.bind_command_key('vms', function(args) return function(args2) return function(args3) Transform(
    {self.iter_jump_to_string, args.n, tochar(args2.keyval) .. tochar(args3.keyval), true},
    {false},
    'all').apply(args.buffer) end end end, 'specified backward, two-chars extend')
  self.bind_command_key('vw', function(args) Transform(
    {false},
    {self.iter_jump_to_word_edge},
    'all').apply(args.buffer) end, 'relative forward word extend')
  self.bind_command_key('vmw', function(args) Transform(
    {self.iter_jump_to_word_edge, true},
    {false},
    'all').apply(args.buffer) end, 'relative backward word extend')
  self.bind_command_key('vr', function(args) Transform(
    {false},
    {self.iter_jump_to_line_end, 0},
    'all').apply(args.buffer) end, 'extend to line end')
  self.bind_command_key('vmr', function(args) Transform(
    {self.iter_jump_to_line_start_or_nonspace_char, args.n},
    {false},
    'all').apply(args.buffer) end, 'extend to line start of fisrt non-space char')
  self.bind_command_key('v[', function(args) Transform(
    {self.iter_jump_to_empty_line, args.n, true},
    {false},
    'all').apply(args.buffer) end, 'extend to previous empty line')
  self.bind_command_key('v]', function(args) Transform(
    {false},
    {self.iter_jump_to_empty_line, args.n},
    'all').apply(args.buffer) end, 'extend to empty line')
  self.bind_command_key('viw', function(args) Transform(
    {self.iter_jump_to_word_edge, true},
    {self.iter_jump_to_word_edge},
    'all').apply(args.buffer) end, 'extend inside word')
  self.bind_command_key('vb', function(args) Transform(
    {false},
    {self.iter_jump_to_indent_block_edge, 0},
    'all').apply(args.buffer) end, 'extend to end of indentation block')
  self.bind_command_key('vmb', function(args) Transform(
    {self.iter_jump_to_indent_block_edge, 0, true},
    {false},
    'all').apply(args.buffer) end, 'extend to start of indentation block')
  self.bind_command_key('vib', function(args) Transform(
    {self.iter_jump_to_indent_block_edge, 0, true},
    {self.iter_jump_to_indent_block_edge, 0},
    'all').apply(args.buffer) end, 'extend inside indentation block')
  self.bind_command_key('v%', function(args) Transform(
    {false},
    {self.iter_jump_to_matching_bracket},
    'all').apply(args.buffer) end, 'forward extend to matching bracket')

  self.selection_extend_subkeymap = self.get_command_subkeymap('v')

  -- numeric prefix in selection extend
  for i = 0, 9 do
    self.bind_command_key('v' .. tostring(i), function(args)
      self.n = self.n * 10 + i
      return self.selection_extend_subkeymap
    end, 'numeric prefix')
  end

  -- brackets in selection extend
  for left, right in pairs(self.BRACKETS) do
    self.bind_command_key('vi' .. left, function(args) Transform(
      {self.selection_brackets_expand, left, right, false},
      {'single'}, 'all').apply(args.buffer)
    end, 'extend inside ' .. left .. right)
    self.bind_command_key('va' .. left, function(args) Transform(
      {self.selection_brackets_expand, left, right, true},
      {'single'}, 'all').apply(args.buffer)
    end, 'extend around ' .. left .. right)
    if right == left then goto continue end
    self.bind_command_key('vi' .. right, function(args) Transform(
      {self.selection_brackets_expand, left, right, false},
      {'single'}, 'all').apply(args.buffer)
    end, 'extend inside ' .. left .. right)
    self.bind_command_key('va' .. right, function(args) Transform(
      {self.selection_brackets_expand, left, right, true},
      {'single'}, 'all').apply(args.buffer)
    end, 'extend around ' .. left .. right)
    ::continue::
  end

  function self.selection_brackets_expand(sel, buffer, left, right, around)
    local buf = buffer.buf
    local start = buf:get_iter_at_mark(sel.stop)
    local stop = start:copy()

    local balance = 0
    start:backward_char()
    local found = false
    while true do
      local c = tochar(start:get_char())
      if c == left and balance == 0 then
        found = true
        break
      elseif c == left then
        balance = balance - 1
      elseif c == right then
        balance = balance + 1
      end
      if not start:backward_char() then break end
    end
    if not found then return end
    if not around then start:forward_char() end

    balance = 0
    found = false
    while true do
      local c = tochar(stop:get_char())
      if c == right and balance == 0 then
        found = true
        break
      elseif c == right then
        balance = balance - 1
      elseif c == left then
        balance = balance + 1
      end
      if not stop:forward_char() then break end
    end
    if not found then return end
    if around then stop:forward_char() end

    buf:move_mark(sel.start, start)
    buf:move_mark(sel.stop, stop)
  end

end

decl('Transform')
Transform = class{function(self, start_func, end_func, target)
  self.start_func = start_func[1]
  table.remove(start_func, 1)
  self.start_args = start_func
  self.end_func = end_func[1]
  table.remove(end_func, 1)
  self.end_args = end_func
  self.target = target

  function self.apply(buffer, skip_indicator_update)
    buffer.current_transform = self
    local targets = {buffer.cursor}
    if self.target == 'all' then
      each(function(sel) table.insert(targets, sel) end, buffer.selections)
    end
    local buf = buffer.buf
    for _, sel in ipairs(targets) do
      if self.end_func == 'single' then -- start_func take Selection as first parameter
        self.start_func(sel, buffer, unpack(self.start_args))
      else -- start_func take TextIter as first parameter
        local start_iter = buf:get_iter_at_mark(sel.start)
        local stop_iter = buf:get_iter_at_mark(sel.stop)
        if self.start_func then
          self.start_func(start_iter, buffer, unpack(self.start_args))
        end
        if self.end_func == 'func' then
          self.start_func(stop_iter, buffer, unpack(self.start_args))
        elseif self.end_func == 'iter' then
          stop_iter = start_iter
        elseif self.end_func then
          self.end_func(stop_iter, buffer, unpack(self.end_args))
        end
        buf:move_mark(sel.start, start_iter)
        buf:move_mark(sel.stop, stop_iter)
        -- generate relative points when moving cursor
        if skip_indicator_update then goto continue end
        buffer.emit_signal('reset-relative-indicators')
        if target == 'cursor' then
          local offset
          local last_offset = start_iter:get_offset()
          local offsets = {}
          for i = 1, 50 do
            self.start_func(start_iter, buffer, unpack(self.start_args))
            offset = start_iter:get_offset()
            if offset ~= last_offset then
              table.insert(offsets, offset)
              last_offset = offset
            else
              break
            end
          end
          buffer.emit_signal('set-relative-indicators', offsets)
        end
      end
      ::continue::
    end
    if buffer.delayed_selection_operation then
      buf:begin_user_action()
      buffer.delayed_selection_operation()
      buf:end_user_action()
      buffer.delayed_selection_operation = false
    end
    buffer.last_transform = self
  end
end}
