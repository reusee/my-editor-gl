decl('extra_lua_init')
function extra_lua_init(self)
  -- setup
  self.connect_signal('language-detected', function(buffer)
    if buffer.lang_name ~= 'Lua' then return end

    -- syntax check
    local buf = buffer.buf
    buffer.connect_signal('before-saving', function()
      local line, msg = lua_check_parse_error(buf:get_text(buf:get_start_iter(), buf:get_end_iter(), false))
      if line == 0 then return end
      local it =buf:get_start_iter()
      it:set_line(line - 1)
      buf:place_cursor(it)
      self.show_message(msg, 5000)
    end)

    -- snippets
    local function new_snippet(trigger, name, snippet)
      buffer.add_snippet(name, snippet)
      buffer.add_pattern(trigger, function() buffer.insert_snippet(name) end,
        true, true, function() return true end)
    end

    new_snippet('r/', 'lua_require', {"require '$1'$2"})
    new_snippet('f/', 'lua_function', {'function$1($2)', '$>$3', '$<end$4'})
    new_snippet('if/', 'lua_if', {'if $1 then', '$>$2', '$<end$3'})
    new_snippet('d/', 'lua_local', {'local $1'})
    new_snippet('fo/', 'lua_for', {'for $1 = $2, $3 do', '$>$4', '$<end$5'})
    new_snippet('pa/', 'lua_pairs', {'for $1, $2 in pairs($3) do', '$>$4', '$<end$5'})
    new_snippet('ip/', 'lua_ipairs', {'for $1, $2 in ipairs($3) do', '$>$4', '$<end$5'})
    new_snippet('w/', 'lua_while', {'while $1 do', '$>$2', '$<end$3'})

  end)
end
