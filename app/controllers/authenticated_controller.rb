# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :require_authentication,
                :set_paper_trail_whodunnit,
                :check_roles!

protected

  def require_authentication
    # Check for dev bypass first (works even if identity_authentication_enabled is false)
    if TradeTariffDevHub.dev_bypass_auth_enabled?
      return if session[:dev_bypass].present?

      # Store where user was trying to go
      session[:return_to] = request.fullpath
      redirect_to dev_login_path
      return
    end

    # Only check identity authentication if not using dev bypass
    return unless TradeTariffDevHub.identity_authentication_enabled?

    return if Rails.env.development? # Skip session check in dev, let current_user handle it

    return if user_session.present? && !user_session.renew?

    if user_session.present?
      user_session&.destroy!
      session[:token] = nil
    end

    redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
  end

  def user_session
    @user_session ||= Session.find_by(token: session[:token])
  end

  def organisation
    @organisation ||= if TradeTariffDevHub.dev_bypass_auth_enabled?
                        # In dev bypass mode, use current_user's organisation directly
                        current_user&.organisation
                      elsif user_session&.assumed_organisation_id.present?
                        user_session.assumed_organisation
                      else
                        current_user&.organisation
                      end
  end

  def current_user
    @current_user ||= if TradeTariffDevHub.dev_bypass_auth_enabled?
                        # Only return user if dev bypass session exists
                        session[:dev_bypass].present? ? find_or_create_dev_user(session[:dev_bypass]) : nil
                      else
                        # Use normal session authentication
                        user_session&.user
                      end
  end

  def organisation_id
    organisation&.id
  end

  def user_id
    current_user&.id
  end

  def check_roles!
    # If dev bypass is enabled, user must have session[:dev_bypass]
    # Check this first before any other logic
    if TradeTariffDevHub.dev_bypass_auth_enabled? && session[:dev_bypass].blank?
      return # require_authentication should have already redirected
    end

    # Don't check roles if user isn't authenticated yet
    # (require_authentication will handle redirect)
    return if performed? || response.redirect?
    return if current_user.nil?

    disallowed_redirect! unless allowed?
  end

  def allowed_roles
    ["ott:full"]
  end

  def allowed?
    # Admins have access to everything
    return true if organisation&.admin?

    # Otherwise check the specific roles required
    allowed_roles.none? || allowed_roles.any? { |role| organisation&.has_role?(role) }
  end

  def refresh_session!
    redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true if user.nil?
  end

  def disallowed_redirect!
    redirect_to root_path, alert: "Your user <strong>#{current_user&.email_address}</strong> does not have the required permissions to access this section"
  end

  def find_or_create_dev_user(user_type)
    email = user_type == "admin" ? "dev-admin@transformuk.com" : "dev@transformuk.com"
    user = User.find_or_initialize_by(email_address: email)

    org = Organisation.find_or_create_by!(organisation_name: "#{user_type.capitalize} Dev Org") do |o|
      o.description = "Dev bypass organisation"
    end

    # Ensure roles are assigned regardless of whether user was just created
    if user_type == "admin"
      org.assign_role!("admin") unless org.admin?
    else
      org.assign_role!("ott:full") unless org.has_role?("ott:full")
      org.assign_role!("fpo:full") unless org.has_role?("fpo:full")
    end

    if user.persisted?
      # Ensure existing user is associated with the correct organisation
      user.update!(organisation: org) unless user.organisation == org
    else
      user.organisation = org
      user.user_id = SecureRandom.uuid
      user.save!
    end

    user
  end

  helper_method :current_user, :organisation, :user_session
end
