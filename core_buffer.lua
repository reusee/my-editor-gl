decl('core_buffer_init')
function core_buffer_init(self)
  self.buffers = {}

  self.define_signal('buffer-created')
  self.define_signal('file-loaded')
  self.define_signal('language-detected')

  self._buffer_map = {}

  function self.create_buffer(filename)
    local buffer = Buffer(filename)
    buffer.indent_width = self.default_indent_width
    table.insert(self.buffers, buffer)
    buffer.buf:set_style_scheme(self.style_scheme)
    self.emit_signal('buffer-created', buffer)
    if buffer.lang then
      self.emit_signal('language-detected', buffer)
    end
    self._buffer_map[buffer.buf] = buffer
    return buffer
  end

  function self.gbuffer_to_Buffer(gbuffer)
    return self._buffer_map[gbuffer]
  end

end

decl('Buffer')
Buffer = class{
  function(self, filename)
    self.buf = GtkSource.Buffer()
    if filename then
      filename = abs_path(filename)
    end

    self.filename = filename
    self.preferred_line_offset = 0
    self.indent_width = 0

    self.lang = false
    local language_manager = GtkSource.LanguageManager.get_default()
    local lang = language_manager:guess_language(filename, 'plain/text')
    if lang then
      self.buf:set_language(lang)
      self.lang = lang
    end

    self.buf:set_highlight_syntax(true)
    self.buf:set_highlight_matching_brackets(true)
    self.buf:set_max_undo_levels(-1)
    self.buf:get_insert():set_visible(true)

  end,
}
Buffer.embed('buf')
