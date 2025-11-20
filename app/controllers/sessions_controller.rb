# frozen_string_literal: true

class SessionsController < ApplicationController
  def handle_redirect
    if already_authenticated?
      return redirect_to api_keys_path
    end

    if user.nil?
      redirect_to TradeTariffDevHub.stateful_identity_consumer_url(session), allow_other_host: true
    end

    if params[:state] == session[:state]
      create_user_session!
      session[:token] = session_token
      session.delete(:state)
      redirect_to api_keys_path
    else
      Rails.logger.error("Invalid state parameter.")
      redirect_to root_path, alert: "Authentication failed. Please try again."
    end
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
