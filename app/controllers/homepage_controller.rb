class HomepageController < ApplicationController
  include SessionAuthentication

  before_action :redirect_authenticated_users, only: :index

  def index; end

protected

  def redirect_authenticated_users
    if authenticated?
      redirect_to logged_in_landing_path and return
    end

    clear_authentication! if user_session.present?
  end

  def current_user
    @current_user ||= Session.find_by_token(session[:token])&.user
  end

  def organisation
    @organisation ||= current_user&.organisation
  end

  helper_method :current_user, :organisation
end
