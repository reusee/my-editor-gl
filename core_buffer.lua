local lgi = require 'lgi'
local GtkSource = lgi.require('GtkSource', '3.0')
require 'object'

function core_buffer_init(self)
  self.buffers = {}

  --TODO buffer-created signal
  --TODO file-loaded signal
  --TODO language-detected signal
end

Buffer = class{
  function(self)
    self.buf = GtkSource.Buffer()
  end,
}
Buffer.embed('buf')
