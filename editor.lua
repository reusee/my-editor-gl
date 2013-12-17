require 'core_defs'
require 'core_signal'
require 'core_buffer'
require 'core_key'
require 'core_view'
require 'core_edit'
require 'core_status'
require 'core_layout'
require 'core_file'

decl('Editor')
Editor = class{
  function(self)
    self.widget = Gtk.Overlay()
    self.proxy_gsignal(self.widget.on_realize, 'on_realize')

    function self.create_overlay_label(halign, valign)
      local label = Gtk.Label{halign = halign, valign = valign}
      self.widget:add_overlay(label)
      self.on_realize(function()
        label:hide()
      end)
      return label
    end
  end,

  -- core modules
  core_signal_init,
  core_defs_init,
  core_buffer_init,
  core_key_init,
  core_view_init,
  core_edit_init,
  core_status_init,
  core_layout_init,
  core_file_init,

  function(self)
    -- root grid
    self.root_grid = Gtk.Grid()
    self.widget:add(self.root_grid)

    -- views
    self.views_grid = Gtk.Grid()
    self.views_grid:set_row_homogeneous(true)
    self.views_grid:set_column_homogeneous(true)
    self.root_grid:attach(self.views_grid, 0, 0, 1, 1)

    -- areas
    self.east_area = Gtk.Grid()
    self.root_grid:attach(self.east_area, 1, 0, 1, 1)
    self.west_area = Gtk.Grid()
    self.root_grid:attach(self.west_area, -1, 0, 1, 1)
    self.north_area = Gtk.Grid()
    self.root_grid:attach(self.north_area, 0, -1, 2, 1)
    self.south_area = Gtk.Grid()
    self.root_grid:attach(self.south_area, 0, 1, 2, 1)

    -- font and style
    self.style_scheme_manager = GtkSource.StyleSchemeManager.get_default()
    self.style_scheme_manager:append_search_path(program_path())
    self.style_scheme = self.style_scheme_manager:get_scheme('solarizeddark')

    -- extra modules

    -- buffers
    for _, filename in pairs(argv()) do
      self.create_buffer(filename)
    end
    if #self.buffers == 0 then
      self.create_buffer()
    end

    -- first view
    local view = self.create_view(self.buffers[1].buf)
    self.views_grid:add(view.wrapper)

  end,
}
Editor.embed('widget')
