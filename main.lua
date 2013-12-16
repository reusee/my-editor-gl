require 'Strict'
decl = Strict.declareGlobal
Strict.strong = true

local lgi = require 'lgi'
local Gtk = lgi.require('Gtk', '3.0')
local GtkSource = lgi.require('GtkSource', '3.0')
local GLib = lgi.require('GLib', '2.0')
local Gdk = lgi.Gdk

require 'editor'

decl('MainWindow')
MainWindow = class{function(self)
  self.widget = Gtk.Window{type = Gtk.WindowType.TOPLEVEL}
  self.widget.on_destroy:connect(function()
    Gtk.main_quit()
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

  -- buffers
  --[[
  local args = argv():gmatch('[^%s]+')
  for filename in args do
    print(filename)
    --TODO
  end
  ]]

  --self.editor.create_buffer()
end}
MainWindow.embed('widget')

local win = MainWindow()

-- jobs from golang
decl('check_jobs_hook')
function check_jobs_hook(event, line)
  check_jobs()
end
debug.sethook(check_jobs_hook, 'r')
GLib.timeout_add(GLib.PRIORITY_DEFAULT, 100, function()
  return true
end)

win.widget:show_all()
Gtk.main()
