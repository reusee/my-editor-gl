decl('ViewStack')
decl('core_layout_init')
function core_layout_init(self)
  self.stacks = {}
  ViewStack = class{function(stack)
    stack.widget = Gtk.Stack()
    stack.widget:set_vexpand(true)
    stack.widget:set_hexpand(true)
    stack.widget:show_all()
    table.insert(self.stacks, stack)
    function stack.add(view)
      stack.widget:add_named(view.wrapper, view.buffer.filename)
    end
  end}

  View.mix(function(view)
    local cursor_position = -1
    function view.save_cursor_position()
      local buf = view.buffer.buf
      cursor_position = buf:get_iter_at_mark(buf:get_insert()):get_offset()
    end
    function view.restore_cursor_position()
      local buf = view.buffer.buf
      local it = buf:get_start_iter()
      it:set_offset(cursor_position)
      buf:place_cursor(it)
    end
  end)

  -- split
  local function split_view(view, orientation)
    local wrapper = view.wrapper
    local gstack = wrapper:get_parent()
    local grid = gstack:get_parent()
    local new_view = self.create_view(view.buffer)

    local left = GObject.Value(GObject.Type.INT)
    grid:child_get_property(gstack, 'left-attach', left)
    left = left.value
    local top = GObject.Value(GObject.Type.INT)
    grid:child_get_property(gstack, 'top-attach', top)
    top = top.value

    local new_stack = ViewStack()
    new_stack.widget:add_named(new_view.wrapper, new_view.buffer.filename)

    grid:remove(gstack)
    local new_grid = Gtk.Grid()
    new_grid:set_orientation(orientation)
    new_grid:add(gstack)
    new_grid:add(new_stack.widget)
    new_grid:show_all()
    grid:attach(new_grid, left, top, 1, 1)

    view.save_cursor_position()
    new_view.widget:grab_focus()
  end

  self.bind_command_key(',v', function(args)
    split_view(args.view, Gtk.Orientation.VERTICAL)
  end, 'vertical split current view')
  self.bind_command_key(',f', function(args)
    split_view(args.view, Gtk.Orientation.HORIZONTAL)
  end, 'horizontal split current view')

  -- sibling split
  self.bind_command_key(',s', function(args)
    local view = args.view
    local grid = view.wrapper:get_parent():get_parent()
    local new_view = self.create_view(view.buffer)
    local wrapper = new_view.wrapper
    local new_stack = ViewStack()
    new_stack.widget:add_named(new_view.wrapper, new_view.buffer.filename)
    grid:add(new_stack.widget)
    view.save_cursor_position()
    new_view.widget:grab_focus()
  end, 'sibling split current view')

  local function switch_to_view_at_pos(x, y)
    for _, stack in ipairs(self.stacks) do
      local alloc = stack.widget:get_allocation()
      local win = stack.widget:get_window(Gtk.TextWindowType.WIDGET)
      local _, left, top = win:get_origin()
      local right = left + alloc.width
      local bottom = top + alloc.height
      if x >= left and x <= right and y >= top and y <= bottom then
        local view = self.view_from_wrapper(stack.widget:get_visible_child())
        view.widget:grab_focus()
        view.restore_cursor_position()
        break
      end
    end
  end

  self.bind_command_key('J', function(args)
    local alloc = args.view.widget:get_allocation()
    local win = args.view.widget:get_window(Gtk.TextWindowType.WIDGET)
    local _, x, y = win:get_origin()
    args.view.save_cursor_position()
    switch_to_view_at_pos(x + alloc.width / 3, y + 30 + alloc.height)
  end, 'switch to south view')

  self.bind_command_key('K', function(args)
    local alloc = args.view.widget:get_allocation()
    local win = args.view.widget:get_window(Gtk.TextWindowType.WIDGET)
    local _, x, y = win:get_origin()
    args.view.save_cursor_position()
    switch_to_view_at_pos(x + alloc.width / 3, y - 30)
  end, 'switch to north view')

  self.bind_command_key('H', function(args)
    local alloc = args.view.widget:get_allocation()
    local win = args.view.widget:get_window(Gtk.TextWindowType.WIDGET)
    local _, x, y = win:get_origin()
    args.view.save_cursor_position()
    switch_to_view_at_pos(x - 30, y + alloc.height / 3)
  end, 'switch to west view')

  self.bind_command_key('L', function(args)
    local alloc = args.view.widget:get_allocation()
    local win = args.view.widget:get_window(Gtk.TextWindowType.WIDGET)
    local _, x, y = win:get_origin()
    args.view.save_cursor_position()
    switch_to_view_at_pos(x + 20 + alloc.width, y + alloc.height / 3)
  end, 'switch to east view')

  self.bind_command_key(',z', function(args)
    if #self.stacks == 1 then return end -- dont close last stack
    local gstack = args.view.wrapper:get_parent()
    -- remove views from self.views
    for _, wrapper in ipairs(gstack:get_children()) do
      local view = self.view_from_wrapper(wrapper)
      local i = 1
      while true do
        if i > #self.views then break end
        if self.views[i] == view then -- delete
          table.remove(self.views, i)
        else
          i = i + 1
        end
      end
    end
    -- remoe stack from self.stacks
    local index = 1
    for i = 1, #self.stacks do
      if self.stacks[i].widget == gstack then
        index = i
        table.remove(self.stacks, i)
        break
      end
    end
    index = index - 1
    if index < 1 then index = 1 end
    local next_stack = self.stacks[index]
    gstack:get_parent():remove(gstack)
    local next_view = self.view_from_wrapper(next_stack.widget:get_visible_child())
    next_view.widget:grab_focus()
    next_view.restore_cursor_position()
  end, 'close view stack')

end
