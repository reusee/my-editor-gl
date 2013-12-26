decl('start_trace')
function start_trace()
  local info
  local source
  local prefix = '@/home/reus'
  local prefix_length = #prefix
  debug.sethook(function()
    info = debug.getinfo(2)
    source = info.source
    if source:sub(1, prefix_length) == prefix then
      --print(source, info.currentline)
    end
  end, "c", 2000)
end

decl('stop_trace')
function stop_trace()
  debug.sethook(nil)
end
