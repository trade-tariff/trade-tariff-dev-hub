# frozen_string_literal: true

class SessionsController < ApplicationController
  def handle_redirect
    if already_authenticated?
      # User is already authenticated, check if admin and redirect accordingly
      return redirect_to admin_organisations_path if user_session&.user&.admin?

      return redirect_to api_keys_path
    end

    return redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true if user.nil?

    create_user_session!
    session[:token] = session_token

    # After creating session, check if user is admin and redirect accordingly
    # Use the user variable directly since we just created the session
    if user&.admin?
      redirect_to admin_organisations_path
    else
      redirect_to api_keys_path
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
