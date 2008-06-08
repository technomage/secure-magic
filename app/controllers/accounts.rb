#require File.join(File.dirname(__FILE__), '..', '..', "lib", "authenticated_system", "authenticated_dependencies")
class SecureMagic::Accounts < SecureMagic::Application
  provides :xml

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end
  
  # Authenticates a account by their login name and unencrypted password.  Returns the account or nil.
  def self.authenticate(login, password)
    u = find_activated_authenticated_model_with_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
  
  def new
    only_provides :html
    @account = SecureMagic::Account.new(params[:account] || {})
    display @account
  end
  
  def create
    cookies.delete :auth_token
    
    @account = SecureMagic::Account.new(params[:account])
    @account.site = request.host_name
    if @account.save
      clear_location
      redirect(url(:activate_email_sent, :id => @account.id))
    else
      render :new
    end
  end
  
  def activate
    self.current_account = SecureMagic::Account.find_activated_authenticated_model(params[:activation_code])
    if logged_in? && !current_account.active?
      current_account.activate
    end
    redirect_back_or_default(url(:email_activated, :id => current_account.id))
  end  

  def authenticated?(password)
    crypted_password == encrypt(password)
  end      

  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end
  
  # Encrypts the password with the account salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end
  
  def remember_token?
    remember_token_expires_at && DateTime.now < DateTime.parse(remember_token_expires_at.to_s)
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save
  end

  def remember_me_for(time)
    remember_me_until (Time.now + time)
  end

  # These create and unset the fields required for remembering accounts between browser closes
  # Default of 2 weeks 
  def remember_me
    remember_me_for (Merb::Const::WEEK * 2)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    self.save
  end
        # Returns true if the account has just been activated.
  def recently_activated?
    @activated
  end

  def activated?
   return false if self.new_record?
   !! activation_code.nil?
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end
  
#protected
  
  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
  
  def password_required?
    crypted_password.blank? || !password.blank?
  end

end