function string.isspace(self)
  return self:find('^%s$') ~= nil
end
