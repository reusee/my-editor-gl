decl('core_file_init')
function core_file_init(self)
  local file_chooser = FileChooser(self)

  self.bind_command_key(',b', function(args)
    file_chooser.last_view = view
    --TODO here
  end, 'open file chooser')
end

decl('FileChooser')
FileChooser = class{
  core_signal_init,
  function(self, editor)
    self.editor = editor

    self.grid = Gtk.Grid{orientation = Gtk.Orientation.VERTICAL}
    self.grid:set_vexpand(true)
    self.grid:set_hexpand(true)

    self.entry = Gtk.Entry()
    self.entry:set_alignment(0)
    self.entry:set_hexpand(true)
    self.grid:add(self.entry)

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
    self.grid:add(self.view)

    self.filename = ''
    self.last_view = 0

    local select = self.view:get_selection()
    select:set_mode(Gtk.SelectionMode.BROWSE)
    self.gconnect(select.on_changed, function(_, selection)
      local store, it = selection:get_selected()
      if it then self.filename = self.store[it][1] end
    end)
  end,
}
