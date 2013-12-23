decl('core_file_init')
function core_file_init(self)
  -- file chooser
  local file_chooser = FileChooser(self)
  self.widget:add_overlay(file_chooser.wrapper)
  self.on_realize(function() file_chooser.wrapper:hide() end)

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
    -- switch to buffer
    if buffer then
      file_chooser.last_view.switch_to_buffer(buffer)
    end
  end)

  -- open file chooser
  self.bind_command_key(',b', function(args)
    file_chooser.last_view = args.view
    local current_filename = args.buffer.filename
    file_chooser.update_list(abspath(dirname(current_filename)))
    file_chooser.wrapper:show_all()
    file_chooser.entry:set_text('', -1)
    file_chooser.entry:grab_focus()
  end, 'open file chooser')

  -- save to file
  self.define_signal('before-saving')
  local file_backup_dir = joinpath(homedir(), '.my-editor-file-backup')
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
    backup_filename = joinpath(file_backup_dir, backup_filename)
    self.emit_signal('before-saving', args.buffer)
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
    local buf = args.buffer.buf
    local buffer = args.buffer
    if buf:get_modified() then
      self.show_message('cannot close modified buffer')
      return
    end
    if buffer.filename == '' then
      self.show_message('cannot close unnamed buffer')
      return
    end
    if #self.buffers == 1 then
      self.show_message('cannot close last buffer')
      return
    end
    local index = index_of(buffer, self.buffers)
    table.remove(self.buffers, index)
    index = index + 1
    if index > #self.buffers then index = 1 end
    for _, view in ipairs(self.views) do
      if view.widget:get_buffer() == buf then
        view.switch_to_buffer(self.buffers[index])
      end
    end
    self.show_message('close buffer of ' .. buffer.filename)
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
      local buffer_filename = editor.view_get_buffer(self.last_view).filename
      self.update_list(abspath(dirname(buffer_filename)))
    end, 'text')

    self.define_signal('done')
    local function done()
      self.wrapper:hide()
      self.last_view.widget:grab_focus()
      self.emit_signal('done')
    end
    self.entry.on_key_press_event:connect(function(_, event)
      if event.keyval == Gdk.KEY_Escape then
        self.filename = ''
        done()
      elseif event.keyval == Gdk.KEY_Return then
        if isdir(self.filename) then -- enter subdirectory
          local path = self.filename .. pathsep()
          self.entry:set_text(path)
          self.entry:set_position(-1)
        else
          done()
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
        done()
      end
    end)

    self.filename = ''
    self.last_view = 0

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

    function self.update_list(current_dir)
      local head, tail = splitpath(self.entry:get_text())
      if head == "" then
         head = current_dir
      end
      if head:sub(1, 1) ~= pathsep() then -- relative path
        head = joinpath(current_dir, head)
      end
      self.store:clear()
      local candidates = {}
      local files = listdir(head)
      for _, f in ipairs(files) do
        if fuzzy_match(tail, f) then
          table.insert(candidates, joinpath(head, f))
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
