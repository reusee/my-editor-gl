decl('core_key_init')
function core_key_init(self)
  self.EDIT, self.COMMAND = 1, 2

  self.operation_mode = self.COMMAND
  self.command_key_handler = {}
  self.edit_key_handler = {}

  self.define_signal('key-pressed')
  self.key_pressed_return_value = false

  self.define_signal('key-done')
  self.define_signal('key-prefix')
  self.define_signal('numeric-prefix')
  self.define_signal('key-handler-execute')

  self.define_signal('entered-edit-mode')
  self.define_signal('entered-command-mode')

  self.n = 0
  self.delay_chars = {}
  self.delay_chars_timer = nil

  --TODO bind numeric prefix keys

  --TODO i
  --TODO kd
  --TODO ,h

  --TODO mode indicator

  --TODO command prefix indicator

  function self.handle_key(view, ev_or_keyval)
    print(type(ev_or_keyval))
  end
end
