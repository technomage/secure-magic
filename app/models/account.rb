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
  


  
end