decl('Set')
function Set(t)
  local self = {}
  local set = {}
  if t then each(function(v) rawset(set, v, true) end, t) end
  function self.contains(e)
    return rawget(set, e)
  end
  function self.add(e)
    rawset(set, #set + 1, e)
  end
  function self.update(es)
    each(function(e) rawset(set, e, true) end, es)
  end
  function self.get()
    return set
  end
  return self
end

decl('OrderedSet')
function OrderedSet()
  local self = {}
  local set = {}
  local elems = {}
  function self.add(e)
    if rawget(elems, e) then return end
    rawset(elems, e, true)
    rawset(set, #set + 1, e)
  end
  function self.get(i)
    if i then return set[i]
    else return set end
  end
  return self
end

decl('List')
function List()
  local self = {}
  local list = {}
  function self.append(e)
    rawset(list, #list + 1, e)
  end
  function self.clear()
    for i = 1, #list do
      table.remove(list)
    end
  end
  function self.get(i)
    if i then return list[i]
    else return list end
  end
  function self.pop()
    return table.remove(list, 1)
  end
  return self
end
