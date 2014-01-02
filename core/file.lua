decl('core_file_init')
function core_file_init(self)
  -- file chooser
  local file_chooser = FileChooser(self)
  file_chooser.current_dir = homedir()
  self.widget:add_overlay(file_chooser.wrapper)
  self.on_realize(function()
    if self.start_dir then
      file_chooser.current_dir = self.start_dir
    end
    if #self.buffers == 0 or self.start_dir then
      file_chooser.update_list()
      file_chooser.entry:grab_focus()
    else
      file_chooser.wrapper:hide()
    end
  end)

  local current_view = false

  -- cancel
  file_chooser.connect_signal('cancel', function()
    if #self.buffers > 0 then -- do not close file chooser if no buffer can switch to
      file_chooser.wrapper:hide()
      current_view.widget:grab_focus()
    end
  end)
  -- open file
  file_chooser.connect_signal('done', function()
    local filename = file_chooser.filename
    if filename == '' then return end
    -- create or select buffer
    local buffer = false
    for _, b in ipairs(self.buffers) do
      if b.filename == filename then
        buffer = b
        break
      end
    end
    if not buffer then
      buffer = self.create_buffer(filename)
    end
    if buffer then
      local stack = self.first_stack.widget
      if current_view then
        stack = current_view.wrapper:get_parent()
      end
      -- create or switch to view
      local view
      for _, wrapper in ipairs(stack:get_children()) do
        view = self.view_from_wrapper(wrapper)
        if view.buffer == buffer then -- switch
          goto forelse
        end
      end
      -- create
      view = self.create_view(buffer)
      stack:add_named(view.wrapper, buffer.filename)
      ::forelse::
      stack:set_visible_child(view.wrapper)
      view.widget:grab_focus()
    end
  end)

  -- open file chooser
  self.bind_command_key(',b', function(args)
    current_view = args.view
    local current_filename = args.buffer.filename
    file_chooser.current_dir = abspath(dirname(current_filename))
    file_chooser.update_list()
    file_chooser.wrapper:show_all()
    file_chooser.entry:set_text('', -1)
    file_chooser.entry:grab_focus()
  end, 'open file chooser')

  -- save to file
  Buffer.mix(function(buffer)
    buffer.define_signal('before-saving')
  end)
  local file_backup_dir = joinpath{homedir(), '.my-editor-file-backup'}
  if not fileexists(file_backup_dir) then
    mkdir(self.file_backup_dir)
  end
  local function quote_filename(s)
    s = s:gsub('#', '##')
    s = s:gsub('/', '#s')
    return s
  end
  self.bind_command_key(',w', function(args)
    local buf = args.buffer.buf
    if not buf:get_modified() then return end
    local filename = args.buffer.filename
    if filename == '' then return end
    local tmp_filename = filename .. '.' .. tostring(current_time_in_millisecond())
    local backup_filename = quote_filename(filename) .. '.' .. tostring(current_time_in_millisecond())
    backup_filename = joinpath{file_backup_dir, backup_filename}
    args.buffer.emit_signal('before-saving')
    -- save tmp file
    if createwithmode(tmp_filename, filemode(filename)) then return end
    local f = io.open(tmp_filename, 'w')
    if not f then return end
    if not f:write(buf:get_text(buf:get_start_iter(), buf:get_end_iter(), false)) then
      f:close()
      return
    end
    f:close()
    if movefile(filename, backup_filename) then return end
    rename(tmp_filename, filename)
    buf:set_modified(false)
    self.show_message('buffer saved to ' .. filename)
  end, 'save buffer to file')

  -- close buffer
  self.bind_command_key(',q', function(args)
    local buffer = args.buffer
    local buf = buffer.buf
    if buf:get_modified() then
      self.show_message('cannot close modified buffer')
      return
    end
    -- remove buffer from buffers
    local index = index_of(buffer, self.buffers)
    table.remove(self.buffers, index)
    index = index + 1
    if index > #self.buffers then index = 1 end
    local next_buffer = self.buffers[index]
    -- remove views
    local i = 1
    while true do
      if i > #self.views then break end
      local view = self.views[i]
      if view.buffer == buffer then -- delete
        table.remove(self.views, i)
        local wrapper = view.wrapper
        local gstack = wrapper:get_parent()
        gstack:remove(wrapper)
        if next_buffer then
          self.switch_to_buffer(next_buffer, gstack)
        end
      else
        i = i + 1
      end
    end
    self.show_message('close buffer of ' .. buffer.filename)
    if not next_buffer then -- last buffer closed
      file_chooser.wrapper:show_all()
      file_chooser.update_list()
      file_chooser.entry:set_text('', -1)
      file_chooser.entry:grab_focus()
    end
  end, 'close buffer')
end

decl('FileChooser')
FileChooser = class{
  signal_init,
  function(self, editor)
    self.editor = editor

    self.wrapper = Gtk.Grid{orientation = Gtk.Orientation.VERTICAL}
    self.wrapper:set_vexpand(true)
    self.wrapper:set_hexpand(true)

    self.entry = Gtk.Entry()
    self.entry:set_alignment(0)
    self.entry:set_hexpand(true)
    self.wrapper:add(self.entry)
    self.entry.on_notify:connect(function()
      self.update_list()
    end, 'text')

    self.define_signal('done')
    self.define_signal('cancel')
    self.entry.on_key_press_event:connect(function(_, event)
      if event.keyval == Gdk.KEY_Escape then
        self.filename = ''
        self.emit_signal('cancel')
      elseif event.keyval == Gdk.KEY_Return then
        if isdir(self.filename) then -- enter subdirectory
          local path = self.filename .. pathsep()
          self.entry:set_text(path)
          self.entry:set_position(-1)
        else
          self.wrapper:hide()
          self.emit_signal('done')
        end
      end
    end)

    self.store = Gtk.ListStore.new{GObject.Type.STRING}

    self.view = Gtk.TreeView{
      id = 'view',
      model = self.store,
      Gtk.TreeViewColumn{
        title = 'path',
        {
          Gtk.CellRendererText{},
          { text = 1 },
        }}}
    self.view:set_headers_visible(false)
    self.wrapper:add(self.view)
    self.view.on_row_activated:connect(function(_, path, column)
      if isdir(self.filename) then -- subdirectory
        local path = self.filename .. pathsep()
        self.entry:set_text(path)
        self.entry:grab_focus()
        self.entry:set_position(-1)
      else
        self.wrapper:hide()
        self.emit_signal('done')
      end
    end)

    self.filename = ''
    self.current_dir = false

    local select = self.view:get_selection()
    select:set_mode(Gtk.SelectionMode.BROWSE)
    self.gconnect(select.on_changed, function(_, selection)
      local store, it = select:get_selected()
      if it then self.filename = self.store[it][1] end
    end)

    local function fuzzy_match(key, s)
      local keyI = 1
      local sI = 1
      while keyI <= #key and sI <= #s do
        if s:sub(sI, sI):lower() == key:sub(keyI, keyI):lower() then
          sI = sI + 1
          keyI = keyI + 1
        else
          sI = sI + 1
        end
      end
      return keyI == #key + 1
    end

    function self.update_list()
      local head, tail = splitpath(self.entry:get_text())
      if head == "" then
         head = self.current_dir
      end
      if head:sub(1, 1) ~= pathsep() then -- relative path
        head = joinpath{self.current_dir, head}
      end
      self.store:clear()
      local candidates = {}
      local files = listdir(head)
      for _, f in ipairs(files) do
        if fuzzy_match(tail, f) then
          table.insert(candidates, joinpath{head, f})
          if #candidates > 30 then break end
        end
      end
      table.sort(candidates, function(a, b) return #a < #b end)
      each(function(f) self.store:append{f} end, candidates)
      select:select_path(Gtk.TreePath.new_from_string('0'))
      self.view:columns_autosize()
    end

  end,
}
