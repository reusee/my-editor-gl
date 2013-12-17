require 'core_defs'
require 'core_signal'
require 'core_buffer'
require 'core_view'
require 'core_key'
require 'core_edit'
require 'core_status'

decl('Editor')
Editor = class{
  function(self)
    self.widget = Gtk.Overlay()

    function self.create_overlay_label(halign, valign)
      local label = Gtk.Label{halign = halign, valign = valign}
      self.widget:add_overlay(label)
      self.widget.on_realize:connect(function()
        label:hide()
      end)
      return label
    end
  end,

  -- core modules
  core_signal_init,
  core_defs_init,
  core_buffer_init,
  core_view_init,
  core_key_init,
  core_edit_init,
  core_status_init,

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

    -- first view
    local first_buffer = self.create_buffer('')
    local first_view = self.create_view(first_buffer.buf)
    self.views_grid:add(first_view.wrapper)

  end,
}
Editor.embed('widget')
