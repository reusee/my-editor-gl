decl('WebKit')
WebKit = lgi.require('WebKit2', '3.0')

decl('extra_webkit_init')
function extra_webkit_init(self)
  local last_view = false

  local WebView = class{}
  WebView.mix(function(webview)
    webview.widget = WebKit.WebView()
    webview.widget.on_context_menu:connect(function() return true end)
    webview.widget.on_key_press_event:connect(function(_, ev)
      if ev.keyval == Gdk.KEY_Escape then
        webview.widget:hide()
        last_view.widget:grab_focus()
      end
    end)
    webview.widget.on_create:connect(function()
      local new_view = WebView()
      return new_view.widget
    end)
    webview.widget.on_ready_to_show:connect(function()
      webview.widget:show_all()
      self.widget:add_overlay(webview.widget)
    end)
  end)

  local webview = WebView()
  webview.widget:show_all()
  self.widget:add_overlay(webview.widget)
  self.on_realize(function() webview.widget:hide() end)

  self.bind_command_key(',r', function(args)
    last_view = args.view
    webview.widget:show()
    webview.widget:load_uri('http://www.bilibili.tv')
    webview.widget:grab_focus()
  end, 'open webkit')
end
