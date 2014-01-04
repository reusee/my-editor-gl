decl('extra_the_silver_searcher_init')
function extra_the_silver_searcher_init(self)
  local locations = {}
  local location_index = 0

  -- parse result
  local function parse_result(result)
    for i = 1, #locations do
      locations[i] = nil
    end
    location_index = 0
    local line
    local current_filename = false
    for i = 1, #result do
      line = result[i]
      if line:sub(1, 1) == ':' then -- filename
        current_filename = line:sub(2, -1)
      elseif line == '' then -- empty line
      else -- result
        for lineno, poses in line:gmatch('(%d+);(.-):') do
          for column, _ in poses:gmatch('(%d+) (%d+)') do
            locations[#locations + 1] = Location(current_filename, tonumber(lineno) - 1, tonumber(column))
          end
        end
      end
    end
    self.show_message('found ' .. tostring(#locations) .. ' results')
  end

  -- jump
  self.bind_command_key(',d', function(args)
    if #locations == 0 then return end
    location_index = location_index + 1
    if location_index > #locations then
      location_index = 1
    end
    locations[location_index].jump()
    self.show_message(tostring(location_index) .. ' / ' .. tostring(#locations) .. ' location')
  end, 'jump to next ag result')

  -- dialog
  local dialog = Gtk.Grid{valign = Gtk.Align.CENTER} -- container
  self.widget:add_overlay(dialog)
  self.on_realize(function() dialog:hide() end)

  local last_view = false
  local pattern_entry = Gtk.Entry()
  local directory_entry = Gtk.Entry()
  local option_entry = Gtk.Entry()

  -- key handler
  local function handle_key(_, ev)
    local keyval = ev.keyval
    if keyval == Gdk.KEY_Escape then
      dialog:hide()
      last_view.widget:grab_focus()
    elseif keyval == Gdk.KEY_Return then
      local pattern = pattern_entry:get_text()
      local dir = directory_entry:get_text()
      local option = option_entry:get_text()
      dialog:hide()
      last_view.widget:grab_focus()
      local result, err = run_the_silver_searcher(pattern, dir, option)
      if err ~= '' then
        self.show_message('AG: ' .. err)
      else
        parse_result(result)
      end
    end
  end

  -- pattern entry
  dialog:attach(Gtk.Label{label = '<span foreground="orange">ag</span>', use_markup = true}, 0, 0, 1, 1)
  pattern_entry:set_hexpand(true)
  dialog:attach(pattern_entry, 1, 0, 1, 1)
  pattern_entry.on_key_press_event:connect(handle_key)

  -- focus handler
  local function handle_focus(widget)
    widget:select_region(0, 0)
    widget:set_position(-1)
  end

  -- directory entry
  dialog:attach(Gtk.Label{label = '<span foreground="orange">dir</span>', use_markup = true}, 0, 1, 1, 1)
  directory_entry:set_hexpand(true)
  dialog:attach(directory_entry, 1, 1, 1, 1)
  directory_entry.on_key_press_event:connect(handle_key)
  directory_entry.on_grab_focus:connect(handle_focus, nil, true)

  -- option entry
  dialog:attach(Gtk.Label{label = '<span foreground="orange">opt</span>', use_markup = true}, 0, 2, 1, 1)
  option_entry:set_hexpand(true)
  dialog:attach(option_entry, 1, 2, 1, 1)
  option_entry.on_key_press_event:connect(handle_key)
  option_entry.on_grab_focus:connect(handle_focus, nil, true)

  -- run
  self.bind_command_key('.s', function(args)
    last_view = args.view
    directory_entry:set_text(Path_abs(Path_dir(args.buffer.filename)))
    dialog:show_all()
    pattern_entry:grab_focus()
  end, 'run the silver searcher')
  self.bind_command_key('.*', function(args)
    last_view = args.view
    directory_entry:set_text(Path_abs(Path_dir(args.buffer.filename)))
    Transform({self.iter_jump_to_word_edge, true}, {self.iter_jump_to_word_edge},
      'cursor').apply(args.buffer)
    local buf = args.buffer.buf
    pattern_entry:set_text(buf:get_text(buf:get_iter_at_mark(buf:get_selection_bound()), buf:get_iter_at_mark(buf:get_insert()), false))
    dialog:show_all()
    pattern_entry:grab_focus()
  end, 'search current word in the silver search')
end
