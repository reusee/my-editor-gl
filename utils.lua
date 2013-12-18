decl('Set')
function Set(t)
  local set = {}
  each(function(v) set[v] = true end, t)

  function set.contains(e)
    return set[e]
  end

  return set
end
