# frozen_string_literal: true

class DevAuthController < ApplicationController
  include DevBypassAuthentication

  def new
    redirect_to default_redirect_path if dev_bypass_user_type.present?
  end

  def create
    user_type = authenticate_password(dev_auth_params[:password])

    if user_type
      session[:dev_bypass] = user_type
      session.delete(:return_to) # Clear return_to but don't use it
      redirect_to default_redirect_path(user_type)
    else
      flash[:alert] = "Invalid password"
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    session.delete(:dev_bypass)
    redirect_to root_path, notice: "You have been logged out."
  end

private

  def authenticate_password(password)
    return nil if password.blank?

    # Use secure comparison to prevent timing attacks
    if ActiveSupport::SecurityUtils.secure_compare(
      password.to_s,
      TradeTariffDevHub.dev_bypass_admin_password.to_s,
    )
      return USER_TYPE_ADMIN
    end

    if ActiveSupport::SecurityUtils.secure_compare(
      password.to_s,
      TradeTariffDevHub.dev_bypass_user_password.to_s,
    )
      return USER_TYPE_USER
    end

    nil
  end

  def default_redirect_path(user_type = dev_bypass_user_type)
    # Get or create the user and organisation for dev bypass
    user = find_or_create_dev_user(user_type) if user_type.present?
    org = user&.organisation

    return organisation_path(org) if org.present?

    # Fallback to root if organisation not available
    root_path
  end

  def dev_auth_params
    params.permit(:password)
  end

  def identity_service_url
    TradeTariffDevHub.identity_consumer_url
  end

  helper_method :identity_service_url
end
