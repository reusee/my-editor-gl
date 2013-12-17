decl('class')
function class(constructors)
  local klass = {}

  -- constructors
  if constructors ~= nil then
    klass.constructors = constructors
  else
    klass.constructors = {}
  end
  klass.embedded_fields = {}

  -- setmetatable
  setmetatable(klass, {
    -- new instance
    __call = function(_, ...)
      local self = {}
      -- signal proxy
      function self.proxy_gsignal(signal, name, ...)
        local callbacks = {}
        self[name] = function(func)
          table.insert(callbacks, func)
        end
        signal:connect(function(...)
          for _, func in pairs(callbacks) do
            func(...)
          end
        end, ...)
      end
      -- construct
      for _, constructor in pairs(klass.constructors) do
        constructor(self, ...)
      end
      -- metatable
      setmetatable(self, {
        -- forbid newindex
        __newindex = function(table, key, value)
          error('cannot set object member/property directly ' .. key)
        end,
        -- index embedded field
        __index = function(table, key)
          local v
          for _, field in pairs(klass.embedded_fields) do
            v = self[field][key]
            if v ~= nil then
              return v
            end
          end
        end,
      })
      return self
    end,
  })

  -- add constructor
  function klass.mix(constructor)
    table.insert(klass.constructors, constructor)
  end

  -- set embedded field
  function klass.embed(name)
    table.insert(klass.embedded_fields, name)
  end

  return klass
end

decl('object_test')
function object_test()
  -- new class with constructors
  Foo = class{
    function(self)
      self.foo = 0
    end,
  }

  -- mix constructor
  Foo.mix(function(self)
    self.bar = 0
  end)

  -- set embedded field
  Foo.mix(function(self)
    self.wrapped_baz = {
      baz = function()
        print('BAZ')
      end,
    }
  end)
  Foo.embed('wrapped_baz')

  local o = Foo()
  o.foo = 5
  print(o.foo)

  o.bar = 10
  print(o.bar)

  o.baz()
end

--object_test()
