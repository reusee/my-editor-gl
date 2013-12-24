decl('Vocabulary')
Vocabulary = class{function(self)
  local words = {}
  local word_set = {}
  function self.add(word)
    if word_set[word.text] then return end
    if not word.source then word.source = '' end
    if not word.desc then word.desc = '' end
    table.insert(words, word)
    word_set[word.text] = true
  end
  function self.count() return #words end
  function self.get(i) return words[i] end
  function self.each(func)
    for _, word in ipairs(words) do func(word) end
  end
  function self.clear()
    for _ = 1, #words do table.remove(words) end
    for k, _ in pairs(word_set) do word_set[k] = nil end
  end
end}

local CandidateList = class{function(self)
  local words = {}
  function self.each(func)
    for _, word in ipairs(words) do func(word) end
  end
  function self.clear()
    for _ = 1, #words do table.remove(words) end
  end
  function self.append(word)
    table.insert(words, word)
  end
  function self.sort(cmp)
    table.sort(words, cmp)
  end
  function self.count() return #words end
  function self.shift()
    return table.remove(words, 1)
  end
end}

decl('core_completion_init')
function core_completion_init(self)
  local vocabulary = Vocabulary()

  -- collect words
  Buffer.mix(function(buffer)
    buffer.connect_signal('found-word', function(word)
      vocabulary.add({text = word, source = 'word'})
    end)
    buffer.completion_providers = {}
  end)

  local completion_view = CompletionView()
  self.widget:add_overlay(completion_view.wrapper)
  self.on_realize(function() completion_view.wrapper:hide() end)
  local completion_replacing = false
  local completion_candidates = CandidateList()

  function self.completion_fuzzy_match(text, input)
    if input == text then return false end
    local i = 1 -- for text
    local j = 1 -- for input
    while i <= #text and j <= #input do
      if text:sub(i, i):lower() == input:sub(j, j):lower() then
        i = i + 1
        j = j + 1
      else
        i = i + 1
      end
    end
    return j == #input + 1
  end

  local function show_candidates()
    completion_view.store:clear()
    completion_candidates.each(function(word)
      completion_view.store:append{word.text, word.source, word.desc}
    end)
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

  local current_input = false
  local current_selected = false
  self.define_signal('word-completed')

  local function update_candidates(buffer)
    if completion_replacing then return end
    completion_view.wrapper:hide()
    completion_candidates.clear()
    if current_selected then
      self.emit_signal('word-completed', {
        input = current_input,
        word = current_selected,
        file_type = buffer.lang_name,
      })
      current_input = false
      current_selected = false
    end
    if self.operation_mode ~= self.EDIT then return end
    local candidates = Vocabulary()
    -- from vocabulary
    local buf = buffer.buf
    local input = buf:get_text(
      buf:get_iter_at_mark(buffer.word_start),
      buf:get_iter_at_mark(buffer.word_end), false)
    current_input = input
    current_selected = false
    if input ~= "" then
      local n = 0
      for i = vocabulary.count(), 1, -1 do
        if self.completion_fuzzy_match(vocabulary.get(i).text, input) then
          candidates.add(vocabulary.get(i))
          n = n + 1
          if n > 30 then break end
        end
      end
    end
    -- extra providers
    each(function(provider) provider(buffer, input, candidates) end,
      buffer.completion_providers)
    -- sort and show
    candidates.each(function(word) completion_candidates.append(word) end)
    completion_candidates.sort(function(a, b) return #a.text < #b.text end)
    if completion_candidates.count() > 0 then show_candidates() end
  end

  self.bind_edit_key({Gdk.KEY_Tab}, function(args)
    if completion_candidates.count() == 0 then return 'propagate' end
    local buf = args.buffer.buf
    local start_mark = args.buffer.word_start
    local end_mark = args.buffer.word_end
    local text = buf:get_text(buf:get_iter_at_mark(start_mark), buf:get_iter_at_mark(end_mark), false)
    completion_replacing = true
    buf:begin_user_action()
    buf:delete(buf:get_iter_at_mark(start_mark), buf:get_iter_at_mark(end_mark))
    if current_selected then
      completion_candidates.append(current_selected)
    else
      completion_candidates.append({text = text})
    end
    local word = completion_candidates.shift()
    current_selected = word
    buf:insert(buf:get_iter_at_mark(start_mark), word.text, -1)
    buf:end_user_action()
    completion_replacing = false
    show_candidates()
  end, 'next completion')

  self.connect_signal('buffer-created', function(buffer)
    buffer.on_changed(function() update_candidates(buffer) end)
  end)
  self.connect_signal({'entered-command-mode', 'entered-edit-mode'}, function(buffer)
    update_candidates(buffer)
  end)

end

decl('CompletionView')
CompletionView = class{function(self)
  self.wrapper = Gtk.Grid{halign = Gtk.Align.START, valign = Gtk.Align.START}
  self.store = Gtk.ListStore.new{
    GObject.Type.STRING, -- text
    GObject.Type.STRING, -- source
    GObject.Type.STRING, -- desc
  }
  self.view = Gtk.TreeView{
    model = self.store,
    Gtk.TreeViewColumn{
      {Gtk.CellRendererText{},
        { text = 1 },
      }},
    Gtk.TreeViewColumn{
      {Gtk.CellRendererText{font = '8'},
        { text = 2 },
      }},
    Gtk.TreeViewColumn{
      {Gtk.CellRendererText{},
        { text = 3 },
      }},
    }
  self.view:set_headers_visible(false)
  self.wrapper:add(self.view)
  self.wrapper:show_all()
end}
