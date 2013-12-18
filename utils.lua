decl('Set')
function Set(t)
  local set = {}
  each(function(v) set[v] = true end, t)

  function set.contains(e)
    return set[e]
  end

  return set
end

decl('index_of')
function index_of(table, elem)
  local index = 0
  for i, v in pairs(table) do
    if v == elem then
      index = i
      break
    end
  end
  return index
end
