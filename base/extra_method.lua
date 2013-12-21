function string.isspace(self)
  return self:find('^%s$') ~= nil
end

function string.each(self, func)
  for i = 1, #self do
    func(self:sub(i, i))
  end
end
