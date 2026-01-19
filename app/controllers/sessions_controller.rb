# frozen_string_literal: true

class SessionsController < ApplicationController
  def handle_redirect
    if already_authenticated?
      user_organisation = user_session&.user&.organisation
      return redirect_to organisation_path(user_organisation)
    end

    result = verify_id_token

    if result.expired?
      # Redirect to identity service with cookies intact so it can refresh the token
      return redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
    end

    unless result.valid?
      clear_authentication_cookies
      return redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
    end

    user = User.from_passwordless_payload!(result.payload)
    unless user
      clear_authentication_cookies
      return redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
    end

    create_user_session!(user, result.payload)
    session[:token] = session_token

    redirect_to organisation_path(user.organisation)
  rescue StandardError => e
    Rails.logger.error("Authentication error: #{e.message}")
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def invalid
    Rails.logger.error("Authentication failure #{params[:message]}")
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def destroy
    user_session&.destroy!

    session[:token] = nil
    session[:dev_bypass] = nil # Always clear dev bypass if present
    clear_authentication_cookies

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

  def user_session
    Session.find_by(token: session[:token])
  end

  def already_authenticated?
    user_session.present? && !user_session.renew?
  end

  def clear_authentication_cookies
    cookies.delete(id_token_cookie_name, domain: TradeTariffDevHub.identity_cookie_domain)
    cookies.delete(refresh_token_cookie_name, domain: TradeTariffDevHub.identity_cookie_domain)
  end

  def id_token_cookie_name
    TradeTariffDevHub.id_token_cookie_name
  end

  def refresh_token_cookie_name
    TradeTariffDevHub.refresh_token_cookie_name
  end
end
