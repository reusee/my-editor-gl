decl('core_folding_init')
function core_folding_init(self)
  Buffer.mix(function(buffer)
    buffer.folded_tag = Gtk.TextTag{name = 'folded', font = 'Terminus 2'}
    buffer.buf.tag_table:add(buffer.folded_tag)
    buffer.folded_ranges = {}
    buffer.on_cursor_position(function() -- skip folded area
      local buf = buffer.buf
      local it = buf:get_iter_at_mark(buf:get_insert())
      for _, range in ipairs(buffer.folded_ranges) do
        local start = range[1]
        local stop = range[2]
        local start_iter = buf:get_iter_at_mark(start)
        local stop_iter = buf:get_iter_at_mark(stop)
        if it:in_range(start_iter, stop_iter) then
          local distance1 = it:get_offset() - start_iter:get_offset()
          local distance2 = stop_iter:get_offset() - it:get_offset()
          if distance1 < distance2 then
            buf:place_cursor(stop_iter)
          else
            if start_iter:backward_char() then
              buf:place_cursor(start_iter)
            else
              buf:place_cursor(stop_iter)
            end
          end
        end
      end
    end)

    function buffer.fold_selection()
      local hidden = false
      local buf = buffer.buf
      for _, sel in ipairs(buffer.selections) do
        local start_iter = buf:get_iter_at_mark(sel.start)
        local stop_iter = buf:get_iter_at_mark(sel.stop)
        if start_iter:compare(stop_iter) ~= 0 then
          hidden = true
          buf:apply_tag(buffer.folded_tag, start_iter, end_iter)
        end
      end
      local start_iter = buf:get_iter_at_mark(buf:get_selection_bound())
      local stop_iter = buf:get_iter_at_mark(buf:get_insert())
      if start_iter:compare(stop_iter) ~= 0 then
        hidden = true
        buf:apply_tag(buffer.folded_tag, start_iter, stop_iter)
        table.insert(buffer.folded_ranges, {
          buf:create_mark(nil, start_iter, true), buf:create_mark(nil, stop_iter, true)})
      end
      return hidden
    end
  end)

  self.bind_command_key('z', function(args)
    local func = function()
      if not args.buffer.fold_selection() then
        return false
      end
      args.buffer.clear_selections()
      return true
    end
    if not func() then
      args.buffer.delayed_selection_operation = func
      return self.selection_extend_subkeymap
    end
  end, 'fold selection')

  self.bind_command_key('mz', function(args)
    local buf = args.buffer.buf
    local buffer = args.buffer
    buf:remove_tag(buffer.folded_tag, buf:get_start_iter(), buf:get_end_iter())
    for _, range in ipairs(buffer.folded_ranges) do
      buf:delete_mark(range[1])
      buf:delete_mark(range[2])
    end
    buffer.folded_ranges = {}
  end, 'unfold all')
end
