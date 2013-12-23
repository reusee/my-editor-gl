decl('Selection')

decl('core_selection_init')
function core_selection_init(self)
  -- Selection class
  Selection = class{function(sel, start, stop)
    sel.start = start
    sel.stop = stop
    sel.buffer = self.gbuffer_to_Buffer(start:get_buffer())
  end}

  Buffer.mix(function(buffer)
    buffer.cursor = Selection(buffer.buf:get_selection_bound(), buffer.buf:get_insert())
    buffer.selections = {}

    -- deletion following
    buffer.skip_insert_delete_signals = false
    buffer.delete_range_start_offset = 0
    buffer.delete_range_stop_offset = 0
    buffer.buf.on_delete_range:connect(function(buf, start, stop)
      if self.operation_mode ~= self.EDIT then return end
      if buffer.skip_insert_delete_signals then return end
      local it = buf:get_iter_at_mark(buf:get_insert())
      local start_offset = start:get_offset() - it:get_offset()
      local stop_offset = stop:get_offset() - it:get_offset()
      buffer.delete_range_start_offset = start_offset
      buffer.delete_range_stop_offset = stop_offset
    end)
    buffer.buf.on_delete_range:connect(function(buf, start, stop) -- after
      if self.operation_mode ~= self.EDIT then return end
      if buffer.skip_insert_delete_signals then return end
      local start_mark = buf:create_mark(nil, start)
      local stop_mark = buf:create_mark(nil, stop)
      buffer.skip_insert_delete_signals = true
      for _, selection in ipairs(buffer.selections) do
        local sel_start = buf:get_iter_at_mark(selection.start)
        local sel_stop = buf:get_iter_at_mark(selection.stop)
        sel_start:set_offset(sel_start:get_offset() + buffer.delete_range_start_offset)
        sel_stop:set_offset(sel_stop:get_offset() + buffer.delete_range_stop_offset)
        buf:begin_user_action()
        buf:delete(sel_start, sel_stop)
        buf:end_user_action()
      end
      buffer.skip_insert_delete_signals = false
      start:assign(buf:get_iter_at_mark(start_mark))
      stop:assign(buf:get_iter_at_mark(stop_mark))
      buf:delete_mark(start_mark)
      buf:delete_mark(stop_mark)
    end, nil, true)

    -- insertion following TODO

    buffer.delayed_selection_operation = false

    -- selection toggle
    function buffer.toggle_selection(it)
      local buf = buffer.buf
      if not it then
        it = buf:get_iter_at_mark(buf:get_insert())
      end
      local i = 1
      local selection
      local deleted = false
      while i <= #buffer.selections do
        selection = buffer.selections[i]
        if it:compare(buf:get_iter_at_mark(selection.start)) ~= 0 then
          i = i + 1
          goto continue
        end
        -- off
        deleted = true
        buf:delete_mark(selection.start)
        buf:delete_mark(selection.stop)
        table.remove(buffer.selections, i)
        ::continue::
      end
      if not deleted then -- on
        table.insert(buffer.selections, Selection(
          buf:create_mark(nil, it), buf:create_mark(nil, it)))
      end
    end

    function buffer.clear_selections()
      buffer.selections = {}
      local buf = buffer.buf
      buf:place_cursor(buf:get_iter_at_mark(buf:get_insert()))
    end

    function buffer.jump_selection_mark(backward)
      local buf = buffer.buf
      local offset = buf:get_iter_at_mark(buf:get_insert()):get_offset()
      local mark = false
      local min_diff = 1e16
      for _, selection in ipairs(buffer.selections) do
        local diff = buf:get_iter_at_mark(selection.start):get_offset() - offset
        if backward and diff < 0 and math.abs(diff) < min_diff then
          mark = selection.start
          min_diff = math.abs(diff)
        elseif not backward and diff > 0 and diff < min_diff then
          mark = selection.start
          min_diff = diff
        end
      end
      if mark then
        buf:place_cursor(buf:get_iter_at_mark(mark))
      end
    end
  end)

  self.bind_command_key('t', function(args)
    args.buffer.toggle_selection()
  end, 'toggle selection')
  self.bind_command_key(',c', function(args)
    args.buffer.clear_selections()
  end, 'clear selections')
  self.bind_command_key('{', function(args)
    args.buffer.jump_selection_mark(true)
  end, 'jump to previous selection')
  self.bind_command_key('}', function(args)
    args.buffer.jump_selection_mark()
  end, 'jump to next selection')
  self.bind_command_key('mt', function(args)
    local buffer = args.buffer
    local buf = buffer.buf
    local offset = buf:get_iter_at_mark(buf:get_insert()):get_line_offset()
    for _ = 1, args.n do
      if buf:get_iter_at_mark(buf:get_insert()):get_line_offset() == offset then
        buffer.toggle_selection()
      end
      Transform({self.iter_jump_relative_line_with_preferred_offset, 1},
        {'iter'}, 'cursor').apply(buffer)
    end
  end, 'toggle selections vertically')

  self.bind_command_key(',t', function(args)
    local buffer = args.buffer
    buffer.clear_selections()
    local it = buffer.buf:get_start_iter()
    local tag = buffer.search_result_tag
    while it:forward_to_tag_toggle(tag) do
      if not it:ends_tag(tag) then
        buffer.toggle_selection(it)
      end
    end
  end, 'toggle selections at search results')

  View.mix(function(view)
    -- draw selections
    view.on_draw(function(gview, cr)
      if not gview.is_focus then return end
      local buffer = self.gview_get_buffer(gview)
      local buf = buffer.buf
      local alloc = gview:get_allocation()
      local set_source_rgb = cr.set_source_rgb
      local move_to = cr.move_to
      local set_line_width = cr.set_line_width
      local line_to = cr.line_to
      local stroke = cr.stroke
      local x, y, rect
      for _, selection in ipairs(buffer.selections) do
        rect = gview:get_iter_location(
          buf:get_iter_at_mark(selection.start))
        x, y = gview:buffer_to_window_coords(Gtk.TextWindowType.WIDGET,
          rect.x, rect.y)
        if x > alloc.width or y > alloc.height or x < 0 or y < 0 then
          goto continue
        end
        set_source_rgb(cr, 1, 0, 0)
        move_to(cr, x, y)
        set_line_width(cr, 2)
        line_to(cr, x + 6, y)
        stroke(cr)
        move_to(cr, x, y)
        set_line_width(cr, 1)
        line_to(cr, x, y + rect.height)
        stroke(cr)
        set_source_rgb(cr, 0, 1, 0)
        rect = gview:get_iter_location(
          buf:get_iter_at_mark(selection.stop))
        x, y = gview:buffer_to_window_coords(Gtk.TextWindowType.WIDGET,
          rect.x, rect.y)
        move_to(cr, x, y)
        set_line_width(cr, 1)
        line_to(cr, x, y + rect.height)
        stroke(cr)
        move_to(cr, x, y + rect.height)
        set_line_width(cr, 2)
        line_to(cr, x - 6, y + rect.height)
        stroke(cr)
        ::continue::
      end
    end)
  end)
end
