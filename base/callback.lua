local callbacks = {}

decl('process_go_result')
function process_go_result(tag, res)
  if callbacks[tag] then
    each(function(f) f(res) end, callbacks[tag])
  end
end

decl('register_callback')
function register_callback(tag, func)
  if not callbacks[tag] then callbacks[tag] = {} end
  table.insert(callbacks[tag], func)
end
