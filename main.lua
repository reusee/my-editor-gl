local lgi = require 'lgi'
local Gtk = lgi.require('Gtk', '3.0')
local GtkSource = lgi.require('GtkSource', '3.0')
local GLib = lgi.require('GLib', '2.0')

local win = Gtk.Window{type = Gtk.WindowType.TOPLEVEL}
win.on_destroy:connect(function()
  Gtk.main_quit()
  exit()
end)

scroll = Gtk.ScrolledWindow()
win:add(scroll)

local view = GtkSource.View()
scroll:add(view)

local buffer = view:get_buffer()
buffer.on_changed:connect(function(w)
  print('changed')
end)

local sig = GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, 10, function()
  print('signal')
  return true
end)

win:show_all()
initialized()
Gtk.main()
