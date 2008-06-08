# require  'lib/authenticated_system_controller'
#require File.join(File.dirname(__FILE__), '..', '..', "lib", "authenticated_system", "authenticated_dependencies")
class SecureMagic::Session < SecureMagic::Application
  
  def new
    render
  end

  def create
    self.current_account = SecureMagic::Account.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_account.remember_me
        cookies[:auth_token] = { :value => self.current_account.remember_token , :expires => self.current_account.remember_token_expires_at }
      end
      redirect_back_or_default('/')
    else
      render :new
    end
  end

  def destroy
    self.current_account.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    redirect_back_or_default('/')
  end

  def app_layout
    host = request.host_name
    puts "Request host: #{host}"
    host
  end
  
end