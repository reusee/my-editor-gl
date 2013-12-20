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
