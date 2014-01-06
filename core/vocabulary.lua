decl('core_vocabulary_init')
function core_vocabulary_init(self)
  Buffer.mix(function(buffer)
    local compiled_word_regex = compile_regex(buffer.word_regex)
    buffer.compiled_word_regex = compiled_word_regex

    buffer.on_changed(function()
      collect_words(buffer.native, self.operation_mode == self.EDIT, compiled_word_regex)
    end)
  end)

  self.connect_signal('buffer-created', function(buffer)
    collect_words(buffer.native, false, buffer.compiled_word_regex)
  end)
  self.connect_signal('entered-command-mode', function(buffer)
    collect_words(buffer.native, false, buffer.compiled_word_regex)
  end)
end
