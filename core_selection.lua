decl('Selection')

decl('core_selection_init')
function core_selection_init(self)
  Selection = class{function(sel, start, stop)
    sel.start = start
    sel.stop = stop
    sel.buffer = self.gbuffer_to_Buffer(start:get_buffer())
  end}

  Buffer.mix(function(self)
    self.cursor = Selection(self.buf:get_selection_bound(), self.buf:get_insert())
    self.selections = {}
  end)
end
