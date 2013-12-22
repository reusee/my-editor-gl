decl('core_operation_init')
function core_operation_init(self)
  Buffer.mix(function(buffer)
    function buffer.delete_selection()
      local deleted = false
      local buf = buffer.buf
      buf:begin_user_action()
      for _, sel in ipairs(buffer.selections) do
        local start_iter = buf:get_iter_at_mark(sel.start)
        local stop_iter = buf:get_iter_at_mark(sel.stop)
        if start_iter:compare(stop_iter) ~= 0 then deleted = true end
        buf:delete(start_iter, stop_iter)
      end
      deleted = buf:delete_selection(true, true)
      buf:end_user_action()
      return deleted
    end

    function buffer.copy_selection()
      local has_selection = false
      local buf = buffer.buf
      if buf:get_has_selection() then
        buf:copy_clipboard(self.clipboard)
        has_selection = true
      end
      local number = 1
      for _, sel in ipairs(buffer.selections) do
        local start_iter = buf:get_iter_at_mark(sel.start)
        local stop_iter = buf:get_iter_at_mark(sel.stop)
        if start_iter:compare(stop_iter) == 0 then goto continue end
        has_selection = true
        self.extra_clipboard[number] = buf:get_text(start_iter, stop_iter, false)
        number = number + 1
        ::continue::
      end
      return has_selection
    end
  end)

  self.bind_command_key('d', function(args)
    local buffer = args.buffer
    local func = function()
      if not buffer.copy_selection() then -- nothing is selected
        return false
      end
      buffer.delete_selection()
      buffer.clear_selections()
      return true
    end
    if not func() then
      buffer.delayed_selection_operation = func
      return self.selection_extend_subkeymap
    end
  end, 'delete selection')
end
