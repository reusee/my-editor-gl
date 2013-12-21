decl('core_folding_init')
function core_folding_init(self)
  Buffer.mix(function(buffer)
    buffer.folded_tag = Gtk.TextTag{name = 'folded', font = 'Terminus 2'}
    buffer.buf.tag_table:add(buffer.folded_tag)
    buffer.folded_ranges = {}
    buffer.on_cursor_position(function() -- skip folded area
      local buf = buffer.buf
      local it = buf:get_iter_at_mark(buf:get_insert())
      for _, range in ipairs(buffer.folded_ranges) do
        local start = range[1]
        local stop = range[2]
        local start_iter = buf:get_iter_at_mark(start)
        local stop_iter = buf:get_iter_at_mark(stop)
        if it:in_range(start_iter, end_iter) then
          local distance1 = it:get_offset() - start_iter:get_offset()
          local distance2 = stop_iter:get_offset() - it:get_offset()
          if distance1 < distance2 then
            buf:place_cursor(stop_iter)
          else
            if start_iter:backward_char() then
              buf:place_cursor(start_iter)
            else
              buf:place_cursor(stop_iter)
            end
          end
        end
      end
    end)
  end)

  --TODO fold selection
  --TODO unfold all
end
