class SecureMagic::Application < Merb::Controller
  
  controller_for_slice
  
  def use_app_layout
    self.send Application.default_render_options[:layout]
  end
  
end