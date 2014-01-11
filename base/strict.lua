function decl(key)
  rawset(_G, key, false)
end

_ = false

setmetatable(_G, {
  __index = function(_, key)
    error(key .. ' is not in globals')
  end,
  __newindex = function(_, key)
    error(key .. ' is not declared')
  end
})
