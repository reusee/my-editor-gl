local lgi = require 'lgi'
local Gtk = lgi.require('Gtk', '3.0')
local GtkSource = lgi.require('GtkSource', '3.0')
local GLib = lgi.require('GLib', '2.0')

local win = Gtk.Window{type = Gtk.WindowType.TOPLEVEL}
win.on_destroy:connect(function()
  Gtk.main_quit()
end)

scroll = Gtk.ScrolledWindow()
win:add(scroll)

local view = GtkSource.View()
scroll:add(view)

local buffer = view:get_buffer()
buffer.on_changed:connect(function(w)
  print(test_lua_go(502, 285, 9.23, false, "foobarbaz"))
end)

function check_jobs_hook(event, line)
  check_jobs()
end

debug.sethook(check_jobs_hook, 'c', 1024)

win:show_all()
Gtk.main()
