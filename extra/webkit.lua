decl('WebKit')
WebKit = lgi.require('WebKit2', '4.0')

decl('extra_webkit_init')
function extra_webkit_init(self)
  local last_view = false

  -- context
  local context = WebKit.WebContext.get_default()
  context:set_cache_model(WebKit.CacheModel.WEB_BROWSER) -- cache model

  -- cookie
  local cookie_manager = context:get_cookie_manager()
  cookie_manager:set_persistent_storage(Path_join{Sys_home(), '.cookies'}, WebKit.CookiePersistentStorage.TEXT)
  cookie_manager:set_accept_policy(WebKit.CookieAcceptPolicy.ALWAYS)

  -- security
  local security_manager = context:get_security_manager()
  print(security_manager) --TODO

  -- spell checking
  context:set_spell_checking_enabled(false)

  -- tls errors policy
  context:set_tls_errors_policy(WebKit.TLSErrorsPolicy.IGNORE)

  -- disk cache
  context:set_disk_cache_directory("/tmp")

  -- download
  context.on_download_started:connect(function(_, download)
    print(download) --TODO
  end)

  -- WebView
  local WebView = class{}
  WebView.mix(function(webview)
    webview.widget = WebKit.WebView{}
    local widget = webview.widget
    -- Esc to close
    widget.on_key_press_event:connect(function(_, ev)
      if ev.keyval == Gdk.KEY_Escape then
        widget:hide()
        last_view.widget:grab_focus()
      end
    end)
    -- create signal
    widget.on_create:connect(function()
      local new_view = WebView()
      return new_view.widget
    end)
    -- ready to show signal
    widget.on_ready_to_show:connect(function()
      widget:show_all()
      self.widget:add_overlay(widget)
    end)
    -- load signal
    widget.on_load_changed:connect(function(_, ev)
      print(widget:get_title(), ev)
      print(widget:get_uri())
    end)
    widget.on_load_failed:connect(function(_, ev, uri, err)
      print('fail', ev, uri, err)
    end)

    -- keyboard control
    local keys = {
      -- navigation
      [Gdk.KEY_b] = function()
        if widget:can_go_back() then widget:go_back() end
      end,
      [Gdk.KEY_n] = function()
        if widget:can_go_forward() then widget:go_forward() end
      end,
      -- loading
      [Gdk.KEY_r] = function()
        widget:reload()
      end,
      [Gdk.KEY_R] = function()
        widget:reload_bypass_cache()
      end,
      [Gdk.KEY_S] = function()
        widget:stop_loading()
      end,
      -- zoom
      [Gdk.KEY_i] = function()
        widget:set_zoom_level(widget:get_zoom_level() + 0.05)
      end,
      [Gdk.KEY_o] = function()
        widget:set_zoom_level(widget:get_zoom_level() - 0.05)
      end,
      [Gdk.KEY_u] = function()
        widget:set_zoom_level(1)
      end,
      -- view source
      [Gdk.KEY_C] = function()
        local mode = widget:get_view_mode()
        if mode == WebKit.ViewMode.WEB then -- view source
          widget:set_view_mode(WebKit.ViewMode.SOURCE)
        else
          widget:set_view_mode(WebKit.ViewMode.WEB)
        end
        widget:reload()
      end
    }
    widget.on_key_press_event:connect(function(_, ev)
      --TODO
      --local cb = keys[ev.keyval]
      --if cb then cb() end
      --return true
      return false
    end)

    -- settings
    local settings = widget:get_settings()
    settings:set_auto_load_images(true)
    settings:set_enable_html5_database(true)
    settings:set_enable_html5_local_storage(true)
    settings:set_enable_java(false)
    settings:set_enable_javascript(true) --TODO
    settings:set_enable_offline_web_application_cache(true)
    settings:set_enable_plugins(true)
    settings:set_enable_xss_auditor(true)
    settings:set_javascript_can_open_windows_automatically(false)
    settings:set_default_charset('utf-8')
    settings:set_enable_developer_extras(false) --TODO
    settings:set_enable_resizable_text_areas(true)
    settings:set_enable_tabs_to_links(false)
    settings:set_enable_dns_prefetching(true)
    settings:set_enable_fullscreen(true)
    settings:set_enable_webaudio(true)
    settings:set_enable_webgl(true)
    settings:set_zoom_text_only(false)
    settings:set_javascript_can_access_clipboard(false)
    settings:set_media_playback_requires_user_gesture(true)
    settings:set_draw_compositing_indicators(true)
    settings:set_enable_site_specific_quirks(true)
    settings:set_enable_page_cache(true)
    print(settings:get_user_agent()) --TODO
    settings:set_enable_smooth_scrolling(true)
    settings:set_enable_accelerated_2d_canvas(true)
    settings:set_enable_write_console_messages_to_stdout(true)

  end)

  -- first view
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
