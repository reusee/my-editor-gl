decl('Set')
function Set(t)
  local set = {}
  for _, v in pairs(t) do set[v] = true end

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
