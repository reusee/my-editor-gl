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
  end)
end
