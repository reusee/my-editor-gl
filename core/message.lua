decl('core_message_init')
function core_message_init(self)
  local message_board = Gtk.Grid{
    orientation = Gtk.Orientation.VERTICAL,
    valign = Gtk.Align.START,
    halign = Gtk.Align.CENTER,
    }
  self.widget:add_overlay(message_board)
  self.on_realize(function() message_board:hide() end)

  local message_history = {}

  self.bind_command_key(',,,', function()
    self.show_message('> yes, sir ' .. Time_current_time_in_millisecond())
  end, 'test message')

  self.bind_command_key(',,h', function()
    local n = 0
    for i = #message_history, 1, -1 do
      _show_message(message_history[i], 5000)
      n = n + 1
      if n == 30 then break end
    end
  end, 'show history message')

  self.bind_command_key(',,c', function()
    message_board:foreach(function(e) e:destroy() end, nil)
  end, 'clear messages')

  local function _show_message(text, timeout)
    if not timeout then timeout = 3000 end
    local label = Gtk.Label{hexpand = true}
    label:set_markup('<span foreground="lightgreen">' .. text .. '</span>')
    message_board:add(label)
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, timeout, function() label:destroy() end)
    message_board:show_all()
  end

  function self.show_message(text, timeout)
    local text = Text_escapemarkup(text)
    table.insert(message_history, text)
    _show_message(text, timeout)
  end
end
