decl('Set')
function Set(t)
  local set = {}
  for _, v in pairs(t) do set[v] = true end

  function set.contains(e)
    return set[e]
  end

  return set
end
