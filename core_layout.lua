decl('core_layout_init')
function core_layout_init(self)
  local function split_view(view, orientation)
    local wrapper = view.wrapper
    local grid = wrapper:get_parent()
    local new_view = self.create_view(view.widget:get_buffer())

    local left = GObject.Value(GObject.Type.INT)
    grid:child_get_property(wrapper, 'left-attach', left)
    left = left.value
    local top = GObject.Value(GObject.Type.INT)
    grid:child_get_property(wrapper, 'top-attach', top)
    top = top.value

    grid:remove(wrapper)
    local new_grid = Gtk.Grid()
    new_grid:set_orientation(orientation)
    new_grid:add(wrapper)
    new_grid:add(new_view.wrapper)
    new_grid:show_all()
    grid:attach(new_grid, left, top, 1, 1)

    new_view.widget:grab_focus()
  end

  self.bind_command_key(',v', function(args)
    split_view(args.view, Gtk.Orientation.VERTICAL)
  end, 'vertical split current view')
  self.bind_command_key(',f', function(args)
    split_view(args.view, Gtk.Orientation.HORIZONTAL)
  end, 'horizontal split current view')

  self.bind_command_key(',s', function(args)
    local view = args.view
    local grid = view.wrapper:get_parent()
    local new_view = self.create_view(view.widget:get_buffer())
    local wrapper = new_view.wrapper
    wrapper:show_all()
    grid:add(wrapper)
    new_view.widget:grab_focus()
  end, 'sibling split current view')

  local function switch_to_view_at_pos(x, y)
    for _, view in pairs(self.views) do
      local alloc = view.widget:get_allocation()
      local win = view.widget:get_window(Gtk.TextWindowType.WIDGET)
      local _, left, top = win:get_origin()
      local right = left + alloc.width
      local bottom = top + alloc.height
      if x >= left and x <= right and y >= top and y <= bottom then
        view.widget:grab_focus()
        break
      end
    end
  end

  self.bind_command_key('J', function(args)
    local alloc = args.view.widget:get_allocation()
    local win = args.view.widget:get_window(Gtk.TextWindowType.WIDGET)
    local _, x, y = win:get_origin()
    switch_to_view_at_pos(x + alloc.width / 3, y + 30 + alloc.height)
  end, 'switch to south view')

  self.bind_command_key('K', function(args)
    local alloc = args.view.widget:get_allocation()
    local win = args.view.widget:get_window(Gtk.TextWindowType.WIDGET)
    local _, x, y = win:get_origin()
    switch_to_view_at_pos(x + alloc.width / 3, y - 30)
  end, 'switch to north view')

  self.bind_command_key('H', function(args)
    local alloc = args.view.widget:get_allocation()
    local win = args.view.widget:get_window(Gtk.TextWindowType.WIDGET)
    local _, x, y = win:get_origin()
    switch_to_view_at_pos(x - 30, y + alloc.height / 3)
  end, 'switch to west view')

  self.bind_command_key('L', function(args)
    local alloc = args.view.widget:get_allocation()
    local win = args.view.widget:get_window(Gtk.TextWindowType.WIDGET)
    local _, x, y = win:get_origin()
    switch_to_view_at_pos(x + 20 + alloc.width, y + alloc.height / 3)
  end, 'switch to east view')

  self.bind_command_key(',z', function(args)
    if #self.views == 1 then return end -- dont close last view
    local wrapper = args.view.wrapper
    local index
    for i, v in pairs(self.views) do
      if v == args.view then index = i break end
    end
    table.remove(self.views, index)
    index = index - 1
    if index < 1 then index = 1 end
    local next_view = self.views[index]
    args.view.widget:freeze_notify()
    wrapper:get_parent():remove(wrapper)
    next_view.widget:grab_focus()
  end, 'close current view')

end
