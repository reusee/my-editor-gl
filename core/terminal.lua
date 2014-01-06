decl('core_terminal_init')
function core_terminal_init(self)
  local function new_terminal(argv)
    local term = Vte.Terminal()
    term:set_cursor_blink_mode(Vte.TerminalCursorBlinkMode.OFF)
    term:set_font(Pango.FontDescription.from_string('Terminus 13'))
    term:set_scrollback_lines(-1)
    local margin = 50
    term:set_margin_top(margin)
    term:set_margin_bottom(margin)
    term:set_margin_start(margin)
    term:set_margin_right(margin)
    term:set_encoding('UTF-8')
    self.widget:add_overlay(term)
    self.on_realize(function() term:hide() end)
    local function run_shell()
      term:fork_command_full(
        Vte.PtyFlags.DEFAULT,
        '.',
        argv,
        {},
        0,
        function() end,
        nil)
    end
    term.on_child_exited:connect(function() run_shell() end)
    term.on_selection_changed:connect(function()
      term:copy_clipboard()
    end)
    run_shell()

    local current_view = false

    term.on_key_press_event:connect(function(_, ev)
      if ev.keyval == Gdk.KEY_Escape then
        term:hide()
        current_view.widget:grab_focus()
      end
    end)

    return function(view)
      current_view = view
      term:show()
      term:grab_focus()
    end
  end

  local fish_term = new_terminal{'/usr/bin/env', 'fish'}
  self.bind_command_key(',e', function(args) fish_term(args.view) end)
  local term1 = new_terminal{'/usr/bin/env', 'fish'}
  self.bind_command_key(',1', function(args) term1(args.view) end)
  local term2 = new_terminal{'/usr/bin/env', 'fish'}
  self.bind_command_key(',2', function(args) term2(args.view) end)
  local term3 = new_terminal{'/usr/bin/env', 'fish'}
  self.bind_command_key(',3', function(args) term3(args.view) end)
  local term4 = new_terminal{'/usr/bin/env', 'fish'}
  self.bind_command_key(',4', function(args) term4(args.view) end)
end
