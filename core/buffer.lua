decl('core_buffer_init')
function core_buffer_init(self)
  self.buffers = {}
  self._buffer_map = {}

  self.define_signal('buffer-created')
  self.define_signal('language-detected')

  -- redraw when line or column changed
  self.connect_signal('buffer-created', function(buffer)
    buffer.connect_signal({'line-changed', 'column-changed'}, function()
      self.emit_signal('should-redraw')
    end)
  end)

  function self.create_buffer(filename)
    -- create GtkSource.Buffer
    local buffer = Buffer(filename)
    if type(buffer) == 'string' then -- error
      self.show_message(buffer .. ' ' .. filename)
      print(buffer .. ' ' .. filename)
      return
    end
    if not buffer then return end -- error
    -- property
    buffer.indent_width = self.default_indent_width
    buffer.buf:set_style_scheme(self.style_scheme)
    self.emit_signal('buffer-created', buffer)
    if buffer.lang then
      self.emit_signal('language-detected', buffer)
    end
    -- register
    table.insert(self.buffers, buffer)
    self._buffer_map[buffer.buf] = buffer
    return buffer
  end

  function self.gbuffer_to_Buffer(gbuffer)
    return self._buffer_map[gbuffer]
  end

end

decl('Buffer')
Buffer = class{
  signal_init,
  function(self, filename)
    self.buf = GtkSource.Buffer()
    self.native = self.buf._native
    if filename then
      filename = Path_abs(filename)
      -- load contents
      local f = io.open(filename, 'r')
      if not f then return 'cannot open file' end
      local content = f:read('*a')
      f:close()
      if not Text_is_valid_utf8(content) then return 'file is not utf8 encoded' end
      self.buf:begin_not_undoable_action()
      self.buf:set_text(content, -1)
      self.buf:end_not_undoable_action()
      self.buf:place_cursor(self.buf:get_start_iter())
      self.buf:set_modified(false)
    end

    self.filename = filename
    if not self.filename then self.filename = '' end
    self.preferred_line_offset = 0
    self.indent_width = -1 -- will be set to default_indent_width
    self.indent_char = ' '

    self.lang = false
    self.lang_name = ''
    local language_manager = GtkSource.LanguageManager.get_default()
    local lang = language_manager:guess_language(filename, 'plain/text')
    if not lang then
      local guess = Text_guess_type(self.buf:get_text(self.buf:get_start_iter(), self.buf:get_end_iter(), false))
      if guess ~= "" then
        lang = language_manager:get_language(guess)
      end
    end
    if lang then
      self.buf:set_language(lang)
      self.lang = lang
      self.lang_name = lang:get_name()
    end

    self.buf:set_highlight_syntax(true)
    self.buf:set_highlight_matching_brackets(true)
    self.buf:set_max_undo_levels(-1)

    -- proxy signal
    self.proxy_gsignal(self.buf.on_changed, 'on_changed')
    self.proxy_gsignal(self.buf.on_notify, 'on_cursor_position', 'cursor-position')

    -- line and column changed signal
    self.define_signal('line-changed')
    self.define_signal('column-changed')
    local current_line = 0
    local current_column = 0
    local function check_changed()
      local it = self.buf:get_iter_at_mark(self.buf:get_insert())
      local line = it:get_line()
      local column = it:get_line_offset()
      if current_line ~= line then
        current_line = line
        self.emit_signal('line-changed', line)
      end
      if current_column ~= column then
        current_column = column
        self.emit_signal('column-changed', column)
      end
    end
    self.on_changed(check_changed)
    self.on_cursor_position(check_changed)

    -- word definition
    function self.is_word_char(c)
      if #c == 0 then return false end
      if c >= 'a' and c <= 'z' then return true end
      if c >= 'A' and c <= 'Z' then return true end
      if c >= '0' and c <= '9' then return true end
      if c == '-' or c == '_' then return true end
      return false
    end
    self.word_regex = '[a-zA-Z0-9-_]+'
  end,
}
Buffer.embed('buf')
