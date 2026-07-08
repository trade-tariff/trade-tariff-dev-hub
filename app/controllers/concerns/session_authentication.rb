# frozen_string_literal: true

module SessionAuthentication
  extend ActiveSupport::Concern

protected

  def authenticated?
    return false if user_session.blank?
    return false unless user_session.current?

    cookie_token = cookies[TradeTariffDevHub.id_token_cookie_name]
    return false if cookie_token.blank?

    user_session.cookie_token_match_for?(cookie_token)
  end

  def logged_in_landing_path
    organisation_path(user_session.user.organisation)
  end
end
