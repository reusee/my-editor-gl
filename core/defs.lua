decl('core_defs_init')
function core_defs_init(self)
  self.default_indent_width = 2
  self.fonts = {
    Pango.FontDescription.from_string('Terminus 11'),
    Pango.FontDescription.from_string('Dina 11'),
  }

  -- font and style
  self.default_scheme = 'oblivion'
  self.style_scheme_manager = GtkSource.StyleSchemeManager.get_default()
  self.style_scheme_manager:append_search_path(Path_join{Sys_program_path(), 'theme'})
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
