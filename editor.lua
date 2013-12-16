local lgi = require 'lgi'
local Gtk = lgi.require('Gtk', '3.0')
local GtkSource = lgi.require('GtkSource', '3.0')

require 'core_defs'
require 'core_buffer'
require 'core_view'

Editor = class{function(self)
  self.widget = Gtk.Overlay()

  -- init core modules
  core_defs_init(self)
  core_buffer_init(self)
  core_view_init(self)

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
  view = self.create_view()
  self.views_grid:add(view.wrapper)
end}
Editor.embed('widget')
