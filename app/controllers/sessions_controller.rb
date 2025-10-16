# frozen_string_literal: true

class SessionsController < ApplicationController
  def handle_redirect
    return redirect_to api_keys_path if already_authenticated?

    return redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true if user.nil?

    create_user_session!
    session[:token] = session_token

    redirect_to api_keys_path
  rescue StandardError => e
    Rails.logger.error("Authentication error: #{e.message}")
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def failure
    Rails.logger.error("Authentication failure: #{params[:message]}")
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def destroy
    user_session&.destroy!

    session[:token] = nil
    cookies.delete(:id_token, domain: TradeTariffDevHub.identity_cookie_domain)
    cookies.delete(:refresh_token, domain: TradeTariffDevHub.identity_cookie_domain)

    redirect_to root_path, notice: "You have been logged out."
  end

private

  def create_user_session!
    Session.create!(
      user: user,
      token: session_token,
      id_token: id_token,
    )
  end

  def session_token
    @session_token ||= SecureRandom.uuid
  end

  def user
    @user ||= User.from_passwordless_payload!(decoded_id_token) if decoded_id_token
  end

  def decoded_id_token
    @decoded_id_token ||= VerifyToken.new(id_token).call
  end

  def id_token
    @id_token ||= cookies[:id_token]
  end

  def user_session
    Session.find_by(token: session[:token])
  end

  def already_authenticated?
    user_session.present? && !user_session.renew?
  end
end
