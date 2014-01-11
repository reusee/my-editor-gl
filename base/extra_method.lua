function string.isspace(self)
  return self:find('^%s$') ~= nil
end

function string.each(self, func)
  for i = 1, #self do
    func(self:sub(i, i))
  end
end

decl('each')
function each(f, t)
  for i = 1, #t do
    f(t[i])
  end
end

decl('index_of')
function index_of(e, t)
  for i = 1, #t do
    if t[i] == e then
      return i
    end
  end
end
