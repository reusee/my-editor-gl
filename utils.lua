decl('Set')
function Set(t)
  local set = {}
  each(function(v) set[v] = true end, t)

  function set.contains(e)
    return set[e]
  end

  return set
end

decl('OrderedSet')
function OrderedSet()
  local set = {}
  local elems = {}
  function set.add(e)
    if rawget(elems, e) then return end
    rawset(elems, e, true)
    rawset(set, #set + 1, e)
  end
  return set
end
