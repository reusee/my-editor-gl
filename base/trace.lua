decl('start_trace')
function start_trace()
  debug.sethook(function()
    local info = debug.getinfo(2)
    print(info.source, info.currentline)
  end, "l")
end

decl('stop_trace')
function stop_trace()
  debug.sethook(nil)
end
