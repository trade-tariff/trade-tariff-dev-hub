# frozen_string_literal: true

class SessionsController < ApplicationController
  def handle_redirect
    log_authentication_context

    if already_authenticated?
      user_organisation = user_session&.user&.organisation
      return redirect_to organisation_path(user_organisation)
    end

    result = verify_id_token

    if result.expired?
      Rails.logger.info("[Auth] Token expired, redirecting to identity service for refresh")
      return redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
    end

    unless result.valid?
      Rails.logger.warn("[Auth] Token validation failed: #{result.reason}")
      clear_authentication!
      return redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
    end

    user = User.from_passwordless_payload!(result.payload)
    unless user
      Rails.logger.warn("[Auth] User not found for payload sub: #{result.payload&.dig('sub')}")
      clear_authentication!
      return redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
    end

    Rails.logger.info("[Auth] Successfully authenticated user: #{user.email_address}")
    create_user_session!(user, result.payload)
    session[:token] = session_token

    redirect_to organisation_path(user.organisation)
  rescue Organisation::InvitationRequiredError => e
    Rails.logger.info("[Auth] User requires invitation: #{e.message}")
    clear_authentication!
    redirect_to root_path, alert: "This service is currently in private beta. You need an invitation from an existing organisation to access it."
  rescue StandardError => e
    Rails.logger.error("[Auth] Authentication error: #{e.class}: #{e.message}")
    Rails.logger.error("[Auth] Backtrace: #{e.backtrace&.first(5)&.join("\n")}")
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def invalid
    Rails.logger.error("Authentication failure #{params[:message]}")
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def destroy
    clear_authentication!(full: true)

    redirect_to root_path, notice: "You have been logged out."
  end

private

  def create_user_session!(user, payload)
    Session.create!(
      user: user,
      token: session_token,
      id_token: id_token,
      raw_info: payload,
    )
  end

  def session_token
    @session_token ||= SecureRandom.uuid
  end

  def verify_id_token
    @verify_id_token ||= VerifyToken.new(id_token).call
  end

  def id_token
    @id_token ||= cookies[id_token_cookie_name]
  end

  def already_authenticated?
    return false if user_session.blank?
    return false unless user_session.current?

    # Check cookie matching only if cookie is present
    # If cookie doesn't match, return false to allow re-authentication via callback
    cookie_token = cookies[id_token_cookie_name]
    return false if cookie_token.blank?

    user_session.cookie_token_match_for?(cookie_token)
  end

  def log_authentication_context
    Rails.logger.info("[Auth] Authentication attempt started")
    Rails.logger.info("[Auth] Environment: #{TradeTariffDevHub.environment}")
    Rails.logger.info("[Auth] Cookie domain: #{TradeTariffDevHub.identity_cookie_domain}")
    Rails.logger.info("[Auth] Expected id_token cookie name: #{id_token_cookie_name}")
    Rails.logger.info("[Auth] Expected refresh_token cookie name: #{refresh_token_cookie_name}")
    Rails.logger.info("[Auth] id_token cookie present: #{cookies[id_token_cookie_name].present?}")
    Rails.logger.info("[Auth] refresh_token cookie present: #{cookies[refresh_token_cookie_name].present?}")

    # Log all cookie names (without values) for debugging mismatches
    cookie_names = cookies.to_h.keys
    token_related = cookie_names.select { |name| name.to_s.include?("token") }
    Rails.logger.info("[Auth] All token-related cookies received: #{token_related.inspect}")
  end

  def id_token_cookie_name
    TradeTariffDevHub.id_token_cookie_name
  end

  def refresh_token_cookie_name
    TradeTariffDevHub.refresh_token_cookie_name
  end
end
