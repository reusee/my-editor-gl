decl('core_transform_init')
function core_transform_init(self)
  Buffer.mix(function(self)
    self.current_transform = false
    self.last_transform = false
  end)

  self.bind_command_key(';', function(args)
    args.buffer.last_transform.apply(args.buffer)
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

  --TODO selection moves

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

  function self.apply(buffer)
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
      end
    end
    --TODO delayed selection operation
    buffer.last_transform = self
  end
end}
