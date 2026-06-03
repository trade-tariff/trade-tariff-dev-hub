class HomepageController < ApplicationController
  include DevBypassAuthentication
  include SessionAuthentication

  before_action :redirect_authenticated_users, only: :index

  def index; end

protected

  def redirect_authenticated_users
    if authenticated?
      redirect_to logged_in_landing_path and return
    end

    if dev_bypass_enabled? && dev_bypass_user_type.present?
      user = current_user_with_dev_bypass
      redirect_to organisation_path(user.organisation) and return if user&.organisation
    end

    clear_authentication! if user_session.present?
  end

  def current_user
    @current_user ||= if dev_bypass_enabled?
                        current_user_with_dev_bypass
                      else
                        Session.find_by_token(session[:token])&.user
                      end
  end

  def organisation
    @organisation ||= current_user&.organisation
  end

  helper_method :current_user, :organisation
end
