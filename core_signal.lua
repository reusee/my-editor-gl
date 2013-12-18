decl('core_signal_init')
function core_signal_init(self)
  self._signals = {}

  function self.define_signal(name)
    if self._signals[name] == nil then
      self._signals[name] = {}
    end
  end

  function self.connect_signal(name, func)
    if type(name) == 'table' then
      each(function(n)
        if self._signals[n] == nil then
          error('signal does not exists ' .. n)
        end
        table.insert(self._signals[n], func)
      end, name)
    else
      if self._signals[name] == nil then
        error('signal does not exists ' .. name)
      end
      table.insert(self._signals[name], func)
    end
  end

  function self.emit_signal(name, ...)
    if self._signals[name] == nil then
      error('signal does not exists ' .. name)
    end
    for _, func in ipairs(self._signals[name]) do
      func(...)
    end
  end

  -- safer
  function self.gconnect(signal, func)
    if func == nil then
      error('cannot connect nil value')
    end
    signal:connect(func)
  end

end
