decl('extra_common_snippets_init')
function extra_common_snippets_init(self)
  -- brackets
  self.connect_signal('language-detected', function(buffer)
    local function define(trigger, name, snippet)
      buffer.add_snippet(name, snippet)
      buffer.add_pattern(trigger, function() buffer.insert_snippet(name) end,
        true, true, {function() return true end})
    end
    define('(', 'parentheses', {'($1)$2'})
    define('[', 'square', {'[$1]$2'})
    define('{', 'curly', {'{$1}$2'})
    define('"', 'doublequote', {'"$1"$2'})
    define("'", 'singlequote', {"'$1'$2"})
    define('`', 'backquote', {'`$1`$2'})
  end)
end
