class HomepageController < ApplicationController
  include DevBypassAuthentication

  def index
    # Homepage shows normally - redirect happens when user clicks "Start now"
    # which goes to api_keys_path and triggers AuthenticatedController#require_authentication
  end

protected

  def current_user
    @current_user ||= if dev_bypass_enabled?
                        # Only return user if dev bypass session exists and is valid
                        current_user_with_dev_bypass
                      else
                        # Use normal session authentication
                        Session.find_by_token(session[:token])&.user
                      end
  end

  def organisation
    @organisation ||= current_user&.organisation
  end

  helper_method :current_user, :organisation
end
