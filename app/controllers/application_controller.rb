class ApplicationController < ActionController::Base
  default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder
  allow_browser versions: :modern

  # NOTE: Cleanup of all authentication state:
  # 1. Database Session record
  # 2. Rails session variables
  # 3. Authentication cookies
  def clear_authentication!(full: false)
    Rails.logger.info("[Auth] Clearing session (Dev Hub)")

    # Destroy database session record
    if user_session.present?
      Rails.logger.info("[Auth] Destroying database session for user: #{user_session.user&.email_address}")
      user_session.destroy!
    end

    # Clear Rails session variables
    session[:token] = nil
    session[:authenticated] = nil
    session[:dev_bypass] = nil # Always clear dev bypass if present

    # Delete authentication cookies
    cookies.delete(TradeTariffDevHub.id_token_cookie_name, domain: TradeTariffDevHub.identity_cookie_domain)
    # Delete refresh token only on full logout
    cookies.delete(TradeTariffDevHub.refresh_token_cookie_name, domain: TradeTariffDevHub.identity_cookie_domain) if full

    Rails.logger.info("[Auth] Session cleared")
  end

  def user_session
    @user_session ||= Session.find_by(token: session[:token])
  end
end
