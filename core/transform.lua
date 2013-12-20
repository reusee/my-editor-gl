decl('core_transform_init')
function core_transform_init(self)
  Buffer.mix(function(self)
    self.current_transform = false
    self.last_transform = false
  end)

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
  --TODO jump to matching bracket

  --TODO selection moves

  --TODO selection extends
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
