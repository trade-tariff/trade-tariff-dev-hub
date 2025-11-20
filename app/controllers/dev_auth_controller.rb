# frozen_string_literal: true

class DevAuthController < ApplicationController
  def new
    redirect_to default_redirect_path if session[:dev_bypass].present?
  end

  def create
    password = params[:password]
    user_type = determine_user_type(password)

    if user_type
      session[:dev_bypass] = user_type
      redirect_to session.delete(:return_to) || default_redirect_path(user_type)
    else
      flash[:alert] = "Invalid password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:dev_bypass)
    redirect_to root_path, notice: "You have been logged out."
  end

private

  def determine_user_type(password)
    return "admin" if password == TradeTariffDevHub.dev_bypass_admin_password
    return "user" if password == TradeTariffDevHub.dev_bypass_user_password

    nil
  end

  def default_redirect_path(user_type = session[:dev_bypass])
    case user_type
    when "admin"
      admin_organisations_path
    when "user"
      api_keys_path
    else
      root_path
    end
  end
end
