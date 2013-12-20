local STP = require 'lib.StackTracePlus'
debug.traceback = STP.stacktrace

require 'lib.fun' ()

local lgi = require 'lgi'
Gtk = lgi.require('Gtk', '3.0')
GtkSource = lgi.require('GtkSource', '3.0')
GLib = lgi.require('GLib', '2.0')
Gdk = lgi.Gdk
Pango = lgi.Pango
GObject = lgi.GObject

require 'lib.Strict'
decl = Strict.declareGlobal
Strict.strong = true
decl('_')

require 'object'
require 'utils'
require 'callback'

require 'editor'

decl('MainWindow')
MainWindow = class{function(self)
  self.widget = Gtk.Window{type = Gtk.WindowType.TOPLEVEL}
  self.widget.on_destroy:connect(function()
    main_quit()
  end)
  self.widget:set_title('my editor')

  -- css
  local css_provider = Gtk.CssProvider()
  css_provider:load_from_data(io.open('style.css', 'r'):read('*a'))
  Gtk.StyleContext.add_provider_for_screen(
    Gdk.Screen.get_default(),
    css_provider,
    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

  -- top container
  self.root_container = Gtk.Overlay()
  self.widget:add(self.root_container)

  -- editor
  self.editor = Editor()
  self.root_container:add(self.editor.widget)

end}
MainWindow.embed('widget')

local win = MainWindow()
win.widget:show_all()

main_loop()
