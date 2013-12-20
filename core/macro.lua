decl('core_macro_init')
function core_macro_init(self)
  local macros = {}
  local recording_macro = false
  local recorded_key_events = {{}}
  local indicator = self.create_overlay_label(Gtk.Align.END, Gtk.Align.START)
  indicator:set_margin_right(200)
  indicator:set_markup('<span foreground="yellow">RECORDING</span>')

  self.connect_signal('key-pressed', function(gview, ev)
    if not recording_macro then return end
    table.insert(recorded_key_events[#recorded_key_events],
      gdk_event_copy(ev._native))
  end)

  self.connect_signal('key-done', function()
    if not recording_macro then return end
    table.insert(recorded_key_events, {})
  end)

  self.bind_command_key('.w', function(args)
    if not recording_macro then -- start
      recording_macro = true
      indicator:show()
    else -- stop
      return function(args)
        recording_macro = false
        local key = tochar(args.keyval)
        table.remove(recorded_key_events, #recorded_key_events)
        macros[key] = recorded_key_events
        indicator:hide()
        self.show_message('macro saved ' .. key)
        recorded_key_events = {{}}
      end
    end
  end, 'toggle macro recording')

  self.bind_command_key('mw', function(args) return function(args1)
    local key = tochar(args1.keyval)
    local macro = macros[key]
    if not macro then
      self.show_message('no macro defined as ' .. key)
      return
    end
    self.show_message('replay macro ' .. key)
    local gview = args.view.widget
    for _ = 1, args.n do
      each(function(group) each(function(event)
        gdk_event_put(event)
      end, group) end, macro)
    end
  end end, 'replay macro')
end
