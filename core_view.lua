local lgi = require 'lgi'
local Gtk = lgi.require('Gtk', '3.0')
local GtkSource = lgi.require('GtkSource', '3.0')

decl('core_view_init')
function core_view_init(self)
  self.views = {}

  self.define_signal('view-created')
  self.connect_signal('view-created', function(view)
    self.gconnect(view.on_key_press_event, self.handle_key)
  end)

  self.define_signal('should-redraw')
  --TODO connect this

  function self.create_view(buf)
    local view = View(buf)
    if buf then view.set_buffer(buf) end
    view.widget:set_indent_width(self.default_indent_width)
    view.widget:modify_font(self.default_font)
    table.insert(self.views, view)
    --TODO update buffer list
    self.emit_signal('view-created', view)
    return view
  end

end

decl('View')
View = class{function(self)
  self.widget = GtkSource.View()

  local scroll = Gtk.ScrolledWindow()
  scroll:set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
  scroll:set_placement(Gtk.CornerType.TOP_RIGHT)
  scroll:set_vexpand(true)
  scroll:set_hexpand(true)
  scroll:add(self.widget)

  local overlay = Gtk.Overlay()
  overlay:set_vexpand(true)
  overlay:set_hexpand(true)
  overlay:add(scroll)

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
