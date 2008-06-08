class SecureMagic::AccountMailer < Merb::MailController
  
  def signup_notification
    @account = params[:account]
    render_mail
  end
  
  def activation_notification
    @account = params[:account]
    render_mail
  end
  
end