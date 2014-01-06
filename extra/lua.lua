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
    local function new_snippet(trigger, name, snippet, line_start)
      buffer.add_snippet(name, snippet)
      local predicts = {function() return true end}
      if line_start then
        predicts = {self.starts_line_p}
      end
      buffer.add_pattern(trigger, function() buffer.insert_snippet(name) end,
        true, true, predicts)
    end

    new_snippet('r/', 'lua_require', {"require '$1'$2"}, true)
    new_snippet('f/', 'lua_function', {'function$1($2)', '$>$3', '$<end$4'})
    new_snippet('ff/', 'lua_oneline_function', {'function($1) $2 end$3'})
    new_snippet('if/', 'lua_if', {'if $1 then', '$>$2', '$<end$3'}, true)
    new_snippet('e/', 'lua_elseif', {'elseif $1 then', '$>$2'})
    new_snippet('d/', 'lua_local', {'local $1'}, true)
    new_snippet('fo/', 'lua_for', {'for $1 = $2, $3 do', '$>$4', '$<end$5'}, true)
    new_snippet('pa/', 'lua_pairs', {'for $1, $2 in pairs($3) do', '$>$4', '$<end$5'}, true)
    new_snippet('ip/', 'lua_ipairs', {'for $1, $2 in ipairs($3) do', '$>$4', '$<end$5'}, true)
    new_snippet('w/', 'lua_while', {'while $1 do', '$>$2', '$<end$3'}, true)
    new_snippet('s/', 'lua_self', {'self.$1'}, true)
    new_snippet('a/', 'lua_assign', {'$1 = $2'}, true)
    new_snippet('n/', 'lua_print', {'print($1)$2'}, true)

  end)
end
