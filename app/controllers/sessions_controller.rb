class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :handle_redirect

  def handle_redirect
    user = User.from_profile!(raw_info)

    session[:user_id] = user.id
    session[:organisation_id] = user.organisation_id
    session[:user_profile] = raw_info

    redirect_to api_keys_path
  rescue StandardError => e
    Rails.logger.error("Authentication error: #{e.message}")
    redirect_to root_path
  end

  def failure
    Rails.logger.error("Authentication failure: #{params[:message]}")
    redirect_to root_path
  end

  def destroy
    session[:user_id] = nil
    session[:organisation_id] = nil
    session[:user_profile] = nil

    redirect_to "/auth/openid_connect/logout"
  end

private

  def raw_info
    @raw_info ||= request.env["omniauth.auth"].extra.raw_info
  end
end
