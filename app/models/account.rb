require 'digest/sha1'
#begin
#  require File.join(File.dirname(__FILE__), '..', '..', "lib", "authenticated_system", "authenticated_dependencies")
#rescue 
#  nil
#end
require 'dm-validations'
class SecureMagic::Account
  include DataMapper::Resource
  #include AuthenticatedSystem::Model
  
  attr_accessor :password, :password_confirmation
  
  property :id,                         Integer, :key => true, :serial => true
  property :login,                      String
  property :email,                      String
  property :crypted_password,           String
  property :salt,                       String
  property :activation_code,            String
  property :activated_at,               DateTime
  property :remember_token_expires_at,  DateTime
  property :remember_token,             String
  property :created_at,                 DateTime
  property :updated_at,                 DateTime
  property :site,                       String
  
  validates_present          :login
  validates_length           :login,                   :in => 5..100
  validates_is_unique        :login
  validates_present          :email
  # validates_format         :email,                   :as => :email_address
  validates_length           :email,                   :in => 3..100
  validates_is_unique        :email
  validates_present          :password,                :if => proc {|a| a.password_required?}
  validates_present          :password_confirmation,   :if => proc {|a| a.password_required?}
  validates_length           :password,                :in => 4..40, :if => proc {|a| a.password_required?}
  validates_is_confirmed     :password,                :groups => :create
    
  before :save, :encrypt_password
  before :create, :make_activation_code
  after :create, :send_signup_notification
  
  def login=(value)
    attribute_set(:login, value.downcase) unless value.nil?
  end

    # Encrypts some data with the salt.
    def self.encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end

    # Authenticates a account by their login name and unencrypted password.  Returns the account or nil.
    def self.authenticate(login, password)
      u = find_activated_authenticated_model_with_login(login) # need to get the salt
      u && u.authenticated?(password) ? u : nil
    end
    
  
  EMAIL_FROM = "info@%s.com"
  SIGNUP_MAIL_SUBJECT = "Welcome to %s.  Please activate your account."
  ACTIVATE_MAIL_SUBJECT = "Welcome to %s"
  
  # Activates the account in the database
  def activate
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save

    # send mail for activation
    SecureMagic::AccountMailer.dispatch_and_deliver(  :activation_notification,
                                  {   :from => (Account::EMAIL_FROM % self.site),
                                      :to   => self.email,
                                      :subject => (Account::ACTIVATE_MAIL_SUBJECT % self.site) },
                                      :account => self )

  end
  
  def send_signup_notification
    begin
      SecureMagic::AccountMailer.dispatch_and_deliver(
        :signup_notification,
      { :from => (Account::EMAIL_FROM % self.site),
        :to  => self.email,
        :subject => (Account::SIGNUP_MAIL_SUBJECT % self.site) },
        :account => self        
        )
    rescue => e
      Merb.logger.error "Error in sending account activation email"
      Merb.logger.error "  #{e} #{e.backtrace}"
    end
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

  def self.find_authenticated_model_with_id(id)
    SecureMagic::Account.first(:id => id)
  end

  def self.find_authenticated_model_with_remember_token(rt)
    SecureMagic::Account.first(:remember_token => rt)
  end

  def self.find_activated_authenticated_model_with_login(login)
    if SecureMagic::Account.instance_methods.include?("activated_at")
      SecureMagic::Account.first(:login => login, :activated_at.not => nil)
    else
      SecureMagic::Account.first(:login => login)
    end
  end

  def self.find_activated_authenticated_model(activation_code)
    SecureMagic::Account.first(:activation_code => activation_code)
  end  

  def self.find_with_conditions(conditions)
    SecureMagic::Account.first(conditions)
  end

  # A method to assist with specs
  def self.clear_database_table
    Account.auto_upgrade!
  end
    
#protected
    
  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
  
  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
end