# frozen_string_literal: true

module SessionAuthentication
  extend ActiveSupport::Concern

protected

  def authenticated?
    return false if user_session.blank?
    return false unless user_session.current?

    # Check cookie matching only if cookie is present
    # If no cookie is present, allow the session (cookie might not be set yet in callback flow)
    cookie_token = cookies[TradeTariffDevHub.id_token_cookie_name]
    return true if cookie_token.blank? # No cookie to check - allow valid session

    # If cookie is present, it must match the session
    user_session.cookie_token_match_for?(cookie_token)
  end

  def logged_in_landing_path
    organisation_path(user_session.user.organisation)
  end
end
