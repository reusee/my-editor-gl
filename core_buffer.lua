local lgi = require 'lgi'
local GtkSource = lgi.require('GtkSource', '3.0')

function core_buffer_init(self)
  self.buffers = {}

  --TODO buffer-created signal
  --TODO file-loaded signal
  --TODO language-detected signal
end

function new_buffer(filename)
  local self = {}
  self.buf = GtkSource.Buffer()
  return self
end
