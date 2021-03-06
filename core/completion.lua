decl('async_update_candidates')
decl('core_completion_init')
function core_completion_init(self)
  -- collect words
  Buffer.mix(function(buffer)
    buffer.completion_providers = new_providers()
    local buf = buffer.buf
    buffer.word_start = buf:create_mark(nil, buf:get_start_iter(), true)
  end)

  local completion_view = CompletionView()
  local store = completion_view.store
  self.widget:add_overlay(completion_view.wrapper)
  self.on_realize(function() completion_view.wrapper:hide() end)
  local completion_replacing = false

  setup_completion(store._native)

  local function show_candidates()
    completion_view.wrapper:show_all()
    completion_view.view:columns_autosize()
    -- set position
    local gview = self.get_current_view().widget
    local buf = self.gview_get_buffer(gview).buf
    local iter_rect = gview:get_iter_location(buf:get_iter_at_mark(buf:get_insert()))
    local x, y = gview:buffer_to_window_coords(Gtk.TextWindowType.WIDGET, iter_rect.x, iter_rect.y)
    y = y + iter_rect.height + 1
    x = x + 8
    local win_rect = self.widget:get_allocation()
    local _, editor_x, editor_y = self.widget:get_window():get_origin()
    local _, view_x, view_y = gview:get_window(Gtk.TextWindowType.WIDGET):get_origin()
    x = x + view_x - editor_x
    y = y + view_y - editor_y
    if y + 100 > win_rect.height then y = y - 100 end
    if x + 100 > win_rect.width then x = x - 200 end
    completion_view.wrapper:set_margin_start(x)
    completion_view.wrapper:set_margin_top(y)
  end

  local current_input = false
  local current_selected = false
  local serial = 0

  function self.update_candidates(buffer)
    if completion_replacing then return end
    completion_view.wrapper:hide()
    store:clear()

    if current_selected then
      on_word_completed({
        file_name = buffer.filename,
        file_type = buffer.lang_name,
        input = current_input,
        text = current_selected[1],
      })
      current_input = false
      current_selected = false
    end

    if self.operation_mode ~= self.EDIT then return end

    local buf = buffer.buf
    local cursor_iter = buf:get_iter_at_mark(buf:get_insert())
    local start_iter = cursor_iter:copy()
    local it = start_iter:copy()
    while it:backward_char() do
      if buffer.is_word_char(chr(it:get_char())) then
        start_iter:backward_char()
      else
        break
      end
    end
    buf:move_mark(buffer.word_start, start_iter)
    local input = buf:get_text(start_iter, cursor_iter, false)
    current_input = input
    current_selected = false

    -- get candidates
    if input == '' then
      local it = buf:get_iter_at_mark(buf:get_insert())
      if it:backward_char() then
        if chr(it:get_char()) ~= '.' then return end
      else
        do return end
      end
    end
    serial = serial + 1
    update_candidates(serial, input, buffer.completion_providers, {
      filename = buffer.filename,
      char_offset = buf:get_iter_at_mark(buf:get_insert()):get_offset(),
      buffer = buffer.native,
      })

    -- show
    if store:get_iter_first() then show_candidates() end
  end

  async_update_candidates = function(s, candidates)
    if s < serial then return end
    if completion_replacing then return end
    completion_view.wrapper:hide()
    if self.operation_mode ~= self.EDIT then return end
    store:clear()
    for i = 1, #candidates do
      store:append(candidates[i])
    end
    if store:get_iter_first() then show_candidates() end
  end

  self.bind_edit_key({Gdk.KEY_Tab}, function(args)
    -- insert tab char if no completion candidate
    if not store:get_iter_first() then return 'propagate' end
    serial = serial + 1 -- prevent append
    local buf = args.buffer.buf
    local start_mark = args.buffer.word_start
    local text = buf:get_text(buf:get_iter_at_mark(start_mark), buf:get_iter_at_mark(buf:get_insert()), false)
    completion_replacing = true
    buf:begin_user_action()
    buf:delete(buf:get_iter_at_mark(start_mark), buf:get_iter_at_mark(buf:get_insert()))
    if current_selected then
      store:append(current_selected)
    else
      store:append{text, 'input'}
    end
    local row = store[store:get_iter_first()]
    current_selected = {row[1], row[2]}
    store:remove(store:get_iter_first())
    buf:insert(buf:get_iter_at_mark(start_mark), current_selected[1], -1)
    buf:end_user_action()
    completion_replacing = false
    show_candidates()
  end, 'next completion')

  self.connect_signal('buffer-created', function(buffer)
    buffer.on_changed(function() self.update_candidates(buffer) end)
  end)
  self.connect_signal({'entered-command-mode', 'entered-edit-mode'}, function(buffer)
    self.update_candidates(buffer)
  end)

end

decl('CompletionView')
CompletionView = class{function(self)
  self.wrapper = Gtk.Grid{halign = Gtk.Align.START, valign = Gtk.Align.START}
  self.store = Gtk.ListStore.new{
    GObject.Type.STRING, -- text
    GObject.Type.STRING, -- desc
  }
  self.view = Gtk.TreeView{
    model = self.store,
    Gtk.TreeViewColumn{
      {Gtk.CellRendererText{},
        { text = 1 },
      }},
    Gtk.TreeViewColumn{
      {Gtk.CellRendererText{font = '10'},
        { text = 2 },
      }},
    }
  self.view:set_headers_visible(false)
  self.wrapper:add(self.view)
  self.wrapper:show_all()
end}
