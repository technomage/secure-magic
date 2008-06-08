module SecureMagic
  module Controller
    protected
      # Returns true or false if the account is logged in.
      # Preloads @current_account with the account model if they're logged in.
      def logged_in?
        current_account != :false
      end
    
      # Accesses the current account from the session.  Set it to :false if login fails
      # so that future calls do not hit the database.
      def current_account
        @current_account ||= (login_from_session || login_from_basic_auth || login_from_cookie || :false)
      end
    
      # Store the given account in the session.
      def current_account=(new_account)
        session[:account] = (new_account.nil? || new_account.is_a?(Symbol)) ? nil : new_account.id
        @current_account = new_account
      end
    
      # Check if the account is authorized
      #
      # Override this method in your controllers if you want to restrict access
      # to only a few actions or if you want to check if the account
      # has the correct rights.
      #
      # Example:
      #
      #  # only allow nonbobs
      #  def authorized?
      #    current_account.login != "bob"
      #  end
      def authorized?
        logged_in?
      end
      
      # Check if the account is authorized and has priviledges
      def priv?
        authorized? && current_account && current_account != :false && current_account.login == "michael"
      end

      # Filter method to enforce a login requirement.
      #
      # To require logins for all actions, use this in your controllers:
      #
      #   before_filter :login_required
      #
      # To require logins for specific actions, use this in your controllers:
      #
      #   before_filter :login_required, :only => [ :edit, :update ]
      #
      # To skip this in a subclassed controller:
      #
      #   skip_before_filter :login_required
      #
      def login_required
        authorized? || throw(:halt, :access_denied)
      end
      
      # Filter method to enforce a priviledged user requirement.
      def priv_required
        priv? || throw(:halt, :access_denied)
      end

      # Redirect as appropriate when an access request fails.
      #
      # The default HTML action is to redirect to the login screen.
      #
      # The default XML action is to render the text Couldn't authenticate you.
      # To provide this response wrapped in XML, make sure to specify an
      # XML layout, such as /app/views/layouts/application.xml.builder.
      #
      # Override this method in your controllers if you want to have special
      # behavior in case the account is not authorized
      # to access the requested action.  For example, a popup window might
      # simply close itself.
      def access_denied
        case content_type
        when :html
          store_location
          redirect url(:login)
        when :xml
          headers["Status"]             = "Unauthorized"
          headers["WWW-Authenticate"]   = %(Basic realm="Web Password")
          self.status = 401
          render "Couldn't authenticate you"
        end
      end
    
      # Store the URI of the current request in the session.
      #
      # We can return to this location by calling #redirect_back_or_default.
      def store_location
        session[:return_to] = request.uri
      end
      
      # Clear the saved URI from the session
      def clear_location
        session[:return_to] = nil
      end
    
      # Redirect to the URI stored by the most recent store_location call or
      # to the passed default.
      def redirect_back_or_default(default)
        loc = session[:return_to] || default
        session[:return_to] = nil
        redirect loc
      end
    
      # Inclusion hook to make #current_account and #logged_in?
      # available as ActionView helper methods.
      # def self.included(base)
      #   base.send :helper_method, :current_account, :logged_in?
      # end

      # Called from #current_account.  First attempt to login by the account id stored in the session.
      def login_from_session
        self.current_account = SecureMagic::Account.find_authenticated_model_with_id(session[:account]) if session[:account]
      end

      # Called from #current_account.  Now, attempt to login by basic authentication information.
      def login_from_basic_auth
        accountname, passwd = get_auth_data
        self.current_account = SecureMagic::Account.authenticate(accountname, passwd) if accountname && passwd
      end

      # Called from #current_account.  Finaly, attempt to login by an expiring token in the cookie.
      def login_from_cookie     
        account = cookies[:auth_token] && SecureMagic::Account.find_authenticated_model_with_remember_token(cookies[:auth_token])
        if account && account.remember_token?
          account.remember_me
          cookies[:auth_token] = { :value => account.remember_token, :expires => account.remember_token_expires_at }
          self.current_account = account
        end
      end
    
      def reset_session
        session.data.each{|k,v| session.data.delete(k)}
      end

    private
      @@http_auth_headers = %w(Authorization HTTP_AUTHORIZATION X-HTTP_AUTHORIZATION X_HTTP_AUTHORIZATION REDIRECT_X_HTTP_AUTHORIZATION)

      # gets BASIC auth info
      def get_auth_data
        auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
        auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
        return auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil] 
      end
  end
end

Merb::BootLoader.after_app_loads do
  Application.send(:include, SecureMagic::Controller)
end