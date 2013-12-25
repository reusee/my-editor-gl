decl('core_view_init')
function core_view_init(self)
  self.views = {}

  self.define_signal('view-created')
  self.connect_signal('view-created', function(view)
    self.gconnect(view.on_key_press_event, self.handle_key)
  end)

  -- view redraw
  self.define_signal('should-redraw')
  -- redraw current view
  self.redraw_time = current_time_in_millisecond()
  self.connect_signal('should-redraw', function()
    if current_time_in_millisecond() - self.redraw_time < 20 then return end
    for _, view in ipairs(self.views) do
      if view.widget.is_focus then
        view.widget:queue_draw()
        self.redraw_time = current_time_in_millisecond()
        return
      end
    end
  end)

  local view_gview_map = {}
  local view_wrapper_map = {}

  function self.create_view(buffer)
    local view = View(buffer)
    view.widget:set_indent_width(self.default_indent_width)
    view.widget:modify_font(self.default_font)
    table.insert(self.views, view)
    self.emit_signal('view-created', view)
    view_gview_map[view.widget] = view
    view_wrapper_map[view.wrapper] = view
    return view
  end

  function self.view_from_gview(gview)
    return view_gview_map[gview]
  end

  function self.view_from_wrapper(wrapper)
    return view_wrapper_map[wrapper]
  end

  function self.gview_get_buffer(gview)
    local gbuffer = gview:get_buffer()
    return self.gbuffer_to_Buffer(gbuffer)
  end

  function self.get_current_view()
    for _, view in ipairs(self.views) do
      if view.widget.is_focus then return view end
    end
  end

  -- buffer switching

  function self.switch_to_buffer(buffer, gstack)
    local exists = false
    local name = GObject.Value(GObject.Type.STRING)
    for _, child in ipairs(gstack:get_children()) do
      gstack:child_get_property(child, 'name', name)
      if name.value == buffer.filename then
        exists = true
        break
      end
    end
    if not exists then -- create view
      local view = self.create_view(buffer)
      gstack:add_named(view.wrapper, buffer.filename)
    end
    gstack:set_visible_child_name(buffer.filename)
    local wrapper = gstack:get_visible_child()
    local view = self.view_from_wrapper(wrapper)
    view.widget:grab_focus()
  end

  self.bind_command_key('>', function(args)
    local index = index_of(args.buffer, self.buffers)
    index = index + 1
    if index > #self.buffers then
      index = 1
    end
    self.switch_to_buffer(self.buffers[index], args.view.wrapper:get_parent())
  end, 'switch to next buffer')

  self.bind_command_key('<', function(args)
    local index = index_of(args.buffer, self.buffers)
    index = index - 1
    if index < 1 then
      index = #self.buffers
    end
    self.switch_to_buffer(self.buffers[index], args.view.wrapper:get_parent())
  end, 'switch to previous buffer')

  -- scroll

  self.bind_command_key('M', function(args)
    local alloc = args.view.widget:get_allocation()
    local buf = args.buffer.buf
    local view = args.view.widget
    local it = view:get_line_at_y(alloc.height - 50 + view:get_vadjustment():get_value())
    buf:place_cursor(it)
    view:scroll_to_mark(buf:get_insert(), 0, true, 1, 0)
  end, 'page down')

  self.bind_command_key('U', function(args)
    local alloc = args.view.widget:get_allocation()
    local buf = args.buffer.buf
    local view = args.view.widget
    local it = view:get_line_at_y(view:get_vadjustment():get_value() - alloc.height)
    buf:place_cursor(it)
    view:scroll_to_mark(buf:get_insert(), 0, true, 1, 0)
  end, 'page up')

  self.bind_command_key('gt', function(args)
    args.view.widget:scroll_to_mark(args.buffer.buf:get_insert(), 0, true, 1, 0)
  end, 'scroll cursor to screen top')
  self.bind_command_key('gb', function(args)
    args.view.widget:scroll_to_mark(args.buffer.buf:get_insert(), 0, true, 1, 1)
  end, 'scroll cursor to screen bottom')
  self.bind_command_key('gm', function(args)
    args.view.widget:scroll_to_mark(args.buffer.buf:get_insert(), 0, true, 1, 0.5)
  end, 'scroll cursor to middle of screen')

  -- auto scroll when moving cursor
  Buffer.mix(function(buffer)
    buffer.on_cursor_position(function()
      for _, view in ipairs(self.views) do
        if view.buffer ~= buffer then goto continue end
        if not view.widget.is_focus then goto continue end
        view.clear_buffer_scroll_state() -- unlock without restore
        view.widget:scroll_to_mark(buffer.buf:get_insert(), 0, false, 0, 0)
        ::continue::
      end
    end)
  end)

  -- lock scrolling
  View.mix(function(view)
    local buffer_scroll_state = {}

    local function lock_vadjustment(adj) -- maintain vadjustment value
      local gview = view.widget
      local buffer = self.gview_get_buffer(gview)
      local state = buffer_scroll_state[buffer]
      if state and adj:get_value() ~= state[2] and state[2] > 0 then
        adj:set_value(state[2])
      end
    end
    view.widget:get_vadjustment().on_changed:connect(function(adj)
      lock_vadjustment(adj)
    end)
    view.widget:get_vadjustment().on_value_changed:connect(function(adj)
      lock_vadjustment(adj)
    end, nil, true)
    local function lock_hadjustment(adj) -- maintain hadjustment value
      local gview = view.widget
      local buffer = self.gview_get_buffer(gview)
      local state = buffer_scroll_state[buffer]
      if state and adj:get_value() ~= state[3] and state[3] > 0 then
        adj:set_value(state[3])
      end
    end
    view.widget:get_hadjustment().on_changed:connect(function(adj)
      lock_hadjustment(adj)
    end)
    view.widget:get_hadjustment().on_value_changed:connect(function(adj)
      lock_hadjustment(adj)
    end, nil, true)

    function view.lock_buffer_scroll()
      local buffer = self.gview_get_buffer(view.widget)
      local buf = buffer.buf
      local gview = view.widget
      buffer_scroll_state[buffer] = {
        buf:get_iter_at_mark(buf:get_insert()):get_offset(),
        gview:get_vadjustment():get_value(),
        gview:get_hadjustment():get_value(),
      }
    end
    function view.clear_buffer_scroll_state() -- unlock without restore
      local buffer = self.gview_get_buffer(view.widget)
      buffer_scroll_state[buffer] = nil
    end
    function view.unlock_buffer_scroll() -- unlock then restore
      local buffer = self.gview_get_buffer(view.widget)
      local state = buffer_scroll_state[buffer]
      if not state then return end
      buffer_scroll_state[buffer] = nil
      local gview = view.widget
      local buf = buffer.buf
      local it = buf:get_start_iter()
      it:set_offset(state[1])
      buf:place_cursor(it)
      if state[2] > 0 then
        view.scroll:get_vadjustment():set_value(state[2])
        view.scroll:get_vadjustment():value_changed()
      end
      if state[3] > 0 then
        view.scroll:get_hadjustment():set_value(state[3])
        view.scroll:get_hadjustment():value_changed()
      end
    end

  end)

end

decl('View')
View = class{function(self, buffer)
  self.buffer = buffer
  local buf = buffer.buf
  if buf == nil then
    error('cannot create view without buffer')
  end
  self.widget = GtkSource.View.new_with_buffer(buf)
  self.proxy_gsignal(self.widget.on_draw, 'on_draw')
  self.proxy_gsignal(self.widget.on_notify, 'on_buffer_changed', 'buffer')
  self.proxy_gsignal(self.widget.on_notify, 'after_buffer_changed', 'buffer', true)
  self.proxy_gsignal(self.widget.on_grab_focus, 'on_grab_focus')
  self.proxy_gsignal(self.widget.on_focus_in_event, 'on_focus_in')
  self.proxy_gsignal(self.widget.on_focus_out_event, 'on_focus_out')

  local scroll = Gtk.ScrolledWindow()
  scroll:set_policy(Gtk.PolicyType.ALWAYS, Gtk.PolicyType.AUTOMATIC)
  scroll:set_placement(Gtk.CornerType.TOP_RIGHT)
  scroll:set_vexpand(true)
  scroll:set_hexpand(true)
  scroll:add(self.widget)
  self.scroll = scroll

  local overlay = Gtk.Overlay()
  overlay:set_vexpand(true)
  overlay:set_hexpand(true)
  overlay:add(scroll)
  overlay:show_all()

  self.wrapper = overlay
  self.overlay = overlay

  self.widget:set_auto_indent(true)
  self.widget:set_indent_on_tab(true)
  self.widget:set_insert_spaces_instead_of_tabs(true)
  self.widget:set_smart_home_end(GtkSource.SmartHomeEndType.BEFORE)
  self.widget:set_show_line_marks(false)
  self.widget:set_show_line_numbers(true)
  self.widget:set_tab_width(2)
  self.widget:set_wrap_mode(Gtk.WrapMode.NONE)

end}
View.embed('widget')
View.mix(signal_init)
