local lgi = require 'lgi'
local Pango = lgi.Pango

function core_defs_init(self)
  self.default_indent_width = 2
  self.default_font = Pango.FontDescription.from_string('Terminus 13')
end
