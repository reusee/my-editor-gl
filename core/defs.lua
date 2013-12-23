decl('core_defs_init')
function core_defs_init(self)
  self.default_indent_width = 2
  self.default_font = Pango.FontDescription.from_string('Terminus 13')
  self.default_scheme = 'molokai'

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
