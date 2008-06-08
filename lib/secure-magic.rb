if defined?(Merb::Plugins)

  require 'merb-slices'
  Merb::Plugins.add_rakefiles "secure-magic/merbtasks", "secure-magic/slicetasks"

  # Register the Slice for the current host application
  Merb::Slices::register(__FILE__)
  
  # Slice configuration - set this in a before_app_loads callback.
  # By default a Slice uses its own layout, so you can swicht to 
  # the main application layout or no layout at all if needed.
  # 
  # Configuration options:
  # :layout - the layout to use; defaults to :secure_magic
  # :mirror - which path component types to use on copy operations; defaults to all
  Merb::Slices::config[:secure_magic][:layout] = :use_app_layout
  
  # load the controller extensions
  require 'secure_magic_controller.rb'
  
  # All Slice code is expected to be namespaced inside a module
  module SecureMagic
    
    # Slice metadata
    self.description = "SecureMagic is a Merb slice for application security!"
    self.version = "0.0.1"
    self.author = "Michael Latta (TechnoMage)"
    
    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded
    end
    
    # Initialization hook - runs before AfterAppLoads BootLoader
    def self.init
    end
    
    # Activation hook - runs after AfterAppLoads BootLoader
    def self.activate
    end
    
    # Deactivation hook - triggered by Merb::Slices.deactivate(SecureMagic)
    def self.deactivate
    end
    
    # Setup routes inside the host application
    #
    # @param scope<Merb::Router::Behaviour>
    #  Routes will be added within this scope (namespace). In fact, any 
    #  router behaviour is a valid namespace, so you can attach
    #  routes at any level of your router setup.
    def self.setup_router(scope)
      puts ("Adding main route for secure-magic slice")
      scope.match("/login").to(:controller => "Session", :action => "create").name(:secure_magic_login)
      scope.match("/logout").to(:controller => "Session", :action => "destroy").name(:secure_magic_logout)
      scope.match("/accounts/activate/:activation_code").to(:controller => "Accounts", :action => "activate").
        name(:secure_magic_account_activation)
      scope.match("/accounts/:id/activate_email_sent").to(:controller => "Accounts", :action => "activate_email_sent").
        name(:secure_magic_activate_email_sent)
      scope.match("/accounts/:id/email_activated").to(:controller => "Accounts", :action => "email_activated").
        name(:secure_magic_email_activated)
      scope.match("/accounts/:id/new_password").to(:controller => "Accounts", :action => "new_password").
        name(:secure_magic_new_password)
      scope.match("/accounts/:id/change_password").to(:controller => "Accounts", :action => "change_password").
        name(:secure_magic_change_password)
      scope.match("/accounts/:id/password_changed").to(:controller => "Accounts", :action => "password_changed").
        name(:secure_magic_passord_changed)
      scope.match("/accounts/lost_password").to(:controller => "Accounts", :action => "lost_password").
        name(:secure_magic_lost_password)
      scope.resources :accounts
      scope.resources :session
    end
    
  end
  
  # Setup the slice layout for SecureMagic
  #
  # Use SecureMagic.push_path and SecureMagic.push_app_path
  # to set paths to secure-magic-level and app-level paths. Example:
  #
  # SecureMagic.push_path(:application, SecureMagic.root)
  # SecureMagic.push_app_path(:application, Merb.root / 'slices' / 'secure-magic')
  # ...
  #
  # Any component path that hasn't been set will default to SecureMagic.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  SecureMagic.setup_default_structure!
  
end