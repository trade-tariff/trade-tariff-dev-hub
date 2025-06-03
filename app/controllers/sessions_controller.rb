# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :handle_redirect

  def handle_redirect
    create_user_session!
    session[:token] = session_token

    redirect_to api_keys_path
  rescue StandardError => e
    Rails.logger.error("Authentication error: #{e.message}")
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def failure
    Rails.logger.error("Authentication failure: #{request.env['omniauth.error']}")
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def destroy
    user_session&.destroy!

    session[:user_profile] = nil
    session[:token] = nil

    redirect_to "/auth/openid_connect/logout"
  end

private

  def create_user_session!
    Session.create!(
      user: user,
      token: session_token,
      expires_at: Time.zone.at(raw_info.exp.to_i),
      raw_info: raw_info.as_json,
    )
  end

  def raw_info
    @raw_info ||= request.env["omniauth.auth"].extra.raw_info
  end

  def session_token
    @session_token ||= SecureRandom.uuid
  end

  def user
    @user ||= User.from_profile!(raw_info)
  end

  def user_session
    Session.find_by(token: session[:token])
  end
end
