decl('core_defs_init')
function core_defs_init(self)
  self.default_indent_width = 2
  self.default_font = Pango.FontDescription.from_string('Terminus 13')

  -- font and style
  self.default_scheme = 'foo'
  self.style_scheme_manager = GtkSource.StyleSchemeManager.get_default()
  self.style_scheme_manager:append_search_path(joinpath{program_path(), 'theme'})
  self.style_scheme = self.style_scheme_manager:get_scheme(self.default_scheme)

  self.BRACKETS = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
    ['<'] = '>',
    ['"'] = '"',
    ["'"] = "'",
    ['`'] = '`',
    ['|'] = '|',
    ['/'] = '/',
    ['-'] = '-',
    ['_'] = '_',
  }
end
