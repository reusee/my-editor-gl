decl('extra_profile_init')
function extra_profile_init(self)
  local is_profiling = false
  self.bind_command_key(',,p', function(args)
    if not is_profiling then -- start
      is_profiling = true
      self.show_message('start golang profile')
      startprofile()
    else
      is_profiling = false
      self.show_message('stop golang profile')
      stopprofile()
    end
  end, 'toggle golang profile')
end
