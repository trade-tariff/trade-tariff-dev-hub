class HomepageController < ApplicationController
  def index; end

  def switch_user
    if Rails.env.development? && params[:email].present?
      session[:dev_user_email] = params[:email]
      redirect_to root_path, notice: "Switched to user: #{params[:email]}"
    else
      redirect_to root_path, alert: "User switching only available in development"
    end
  end

protected

  def current_user
    @current_user ||= if Rails.env.development?
                        # Allow switching between users in development via session
                        session[:dev_user_email] ||= "dev@transformuk.com"
                        User.find_by(email_address: session[:dev_user_email]) || User.dummy_user!
                      end
  end

  def organisation
    @organisation ||= current_user&.organisation
  end

  helper_method :current_user, :organisation
end
