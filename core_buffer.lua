decl('core_buffer_init')
function core_buffer_init(self)
  self.buffers = {}

  self.define_signal('buffer-created')
  self.define_signal('file-loaded')
  self.define_signal('language-detected')

end

decl('Buffer')
Buffer = class{
  function(self)
    self.buf = GtkSource.Buffer()
  end,
}
Buffer.embed('buf')
