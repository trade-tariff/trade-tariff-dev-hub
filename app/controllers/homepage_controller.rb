class HomepageController < ApplicationController
  def index; end

protected

  def current_user
    @current_user ||= if Rails.env.development?
                        # In development, use the same logic as AuthenticatedController
                        session[:dev_user_email] ||= "dev@transformuk.com"
                        User.find_by(email_address: session[:dev_user_email]) || User.dummy_user!
                      else
                        Session.find_by(token: session[:token])&.user
                      end
  end

  def organisation
    @organisation ||= current_user&.organisation
  end

  helper_method :current_user, :organisation
end
