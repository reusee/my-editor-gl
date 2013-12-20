decl('core_completion_init')
function core_completion_init(self)
  local vocabulary = OrderedSet()

  Buffer.mix(function(buffer)
    buffer.connect_signal('found-word', function(word)
      vocabulary.add(word)
    end)
    buffer.completion_providers = {}
  end)

  local completion_view = CompletionView()
  self.widget:add_overlay(completion_view.wrapper)
  self.on_realize(function() completion_view.wrapper:hide() end)
  local completion_replacing = false
  local completion_candidates = List()

  local function fuzzy_match(w, word)
    if w == word then return false end
    local i = 1
    local j = 1
    while i <= #w and j <= #word do
      if w:sub(i, i):lower() == word:sub(j, j):lower() then
        i = i + 1
        j = j + 1
      else
        i = i + 1
      end
    end
    return j == #word + 1
  end

  local function show_candidates()
    completion_view.store:clear()
    each(function(e) completion_view.store:append{e} end, completion_candidates.get())
    completion_view.wrapper:show_all()
    completion_view.view:columns_autosize()
    -- set position
    local view = self.get_current_view().widget
    local buf = self.gview_get_buffer(view).buf
    local iter_rect = view:get_iter_location(buf:get_iter_at_mark(buf:get_insert()))
    local x, y = view:buffer_to_window_coords(Gtk.TextWindowType.WIDGET, iter_rect.x, iter_rect.y)
    y = y + iter_rect.height + 1
    x = x + 8
    local win_rect = self.widget:get_allocation()
    local _, editor_x, editor_y = self.widget:get_window():get_origin()
    local _, view_x, view_y = view:get_window(Gtk.TextWindowType.WIDGET):get_origin()
    x = x + view_x - editor_x
    y = y + view_y - editor_y
    if y + 100 > win_rect.height then y = y - 100 end
    if x + 100 > win_rect.width then x = x - 200 end
    completion_view.wrapper:set_margin_left(x)
    completion_view.wrapper:set_margin_top(y)
  end

  local function update_completion(buffer)
    if completion_replacing then return end
    completion_view.wrapper:hide()
    completion_candidates.clear()
    if self.operation_mode ~= self.EDIT then return end
    local candidates = Set()
    -- from vocabulary
    local buf = buffer.buf
    local word = buf:get_text(
      buf:get_iter_at_mark(buffer.word_start),
      buf:get_iter_at_mark(buffer.word_end), false)
    if word ~= "" then
      local n = 0
      for i = #vocabulary.get(), 1, -1 do
        if fuzzy_match(vocabulary.get(i), word) then
          candidates.add(vocabulary.get(i))
          n = n + 1
          if n > 30 then break end
        end
      end
    end
    -- extra providers
    each(function(provider) provider(buffer, word, candidates) end,
      buffer.completion_providers)
    -- sort and show
    each(function(c) completion_candidates.append(c) end, candidates.get())
    table.sort(completion_candidates.get(), function(a, b) return #a < #b end)
    if #completion_candidates.get() > 0 then show_candidates() end
  end

  self.bind_edit_key({Gdk.KEY_Tab}, function(args)
    if #completion_candidates.get() == 0 then return 'propagate' end
    local buf = args.buffer.buf
    local start_mark = args.buffer.word_start
    local end_mark = args.buffer.word_end
    local text = buf:get_text(buf:get_iter_at_mark(start_mark), buf:get_iter_at_mark(end_mark), false)
    completion_replacing = true
    buf:begin_user_action()
    buf:delete(buf:get_iter_at_mark(start_mark), buf:get_iter_at_mark(end_mark))
    buf:insert(buf:get_iter_at_mark(start_mark), completion_candidates.pop(), -1)
    buf:end_user_action()
    completion_replacing = false
    completion_candidates.append(text)
    show_candidates()
  end, 'next completion')

  self.connect_signal('buffer-created', function(buffer)
    buffer.on_changed(function() update_completion(buffer) end)
  end)
  self.connect_signal({'entered-command-mode', 'entered-edit-mode'}, function(buffer)
    update_completion(buffer)
  end)
end

decl('CompletionView')
CompletionView = class{function(self)
  self.wrapper = Gtk.Grid{halign = Gtk.Align.START, valign = Gtk.Align.START}
  self.store = Gtk.ListStore.new{GObject.Type.STRING}
  self.view = Gtk.TreeView{
    model = self.store,
    Gtk.TreeViewColumn{
      title = 'word',
      {
        Gtk.CellRendererText{},
        { text = 1 },
      }}}
  self.view:set_headers_visible(false)
  self.wrapper:add(self.view)
  self.wrapper:show_all()
end}
