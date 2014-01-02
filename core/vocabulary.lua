decl('core_vocabulary_init')
function core_vocabulary_init(self)
  Buffer.mix(function(buffer)
    local compiled_word_regex = compile_regex(buffer.word_regex)
    buffer.compiled_word_regex = compiled_word_regex

    buffer.on_changed(function()
      trace_tick(true)
      collect_words(buffer.native, self.operation_mode == self.EDIT, compiled_word_regex)
      trace_tick()
    end)
  end)

  self.connect_signal('buffer-created', function(buffer)
    collect_words(buffer.native, false, buffer.compiled_word_regex)
  end)
end
