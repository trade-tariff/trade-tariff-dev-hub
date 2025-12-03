# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  include DevBypassAuthentication

  before_action :require_authentication,
                :set_paper_trail_whodunnit,
                :check_roles!,
                :add_nr_custom_attributes

  def add_nr_custom_attributes
    NewRelic::Agent.add_custom_attributes(
      org_id: organisation&.id,
      client_id: current_user&.id,
    )
  end

protected

  def require_authentication
    # Check for valid identity service session first (regardless of dev bypass setting)
    if TradeTariffDevHub.identity_authentication_enabled? && !Rails.env.development?
      if user_session.present? && !user_session.renew?
        return # Valid identity session exists, proceed without checking dev bypass
      end

      if user_session.present?
        user_session&.destroy!
        session[:token] = nil
      end

      # No valid identity session - fall through to check dev bypass or redirect
    end

    # If dev bypass is enabled and no valid identity session, show dev bypass password page
    if dev_bypass_enabled?
      require_dev_bypass_authentication
      return
    end

    # Dev bypass disabled and no valid identity session - redirect to identity service
    if TradeTariffDevHub.identity_authentication_enabled? && !Rails.env.development?
      redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
    end
  end

  def user_session
    @user_session ||= Session.find_by(token: session[:token])
  end

  def organisation
    @organisation ||= if user_session&.assumed_organisation_id.present?
                        user_session.assumed_organisation
                      elsif user_session&.user.present?
                        user_session.user.organisation
                      elsif dev_bypass_enabled?
                        organisation_with_dev_bypass
                      end
  end

  def current_user
    @current_user ||= if user_session&.user.present?
                        user_session.user
                      elsif dev_bypass_enabled?
                        current_user_with_dev_bypass
                      end
  end

  def organisation_id
    organisation&.id
  end

  def user_id
    current_user&.id
  end

  def check_roles!
    # Skip role check if using dev bypass without a user type set
    if dev_bypass_enabled? && dev_bypass_user_type.blank? && user_session.blank?
      return
    end

    return if performed? || response.redirect?
    return if current_user.nil?

    disallowed_redirect! unless allowed?
  end

  def allowed_roles
    ["trade_tariff:full"]
  end

  def allowed?
    return true if organisation&.admin?

    allowed_roles.none? || allowed_roles.any? { |role| organisation&.has_role?(role) }
  end

  def refresh_session!
    redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true if user.nil?
  end

  def disallowed_redirect!
    redirect_to root_path, alert: "Your user <strong>#{current_user&.email_address}</strong> does not have the required permissions to access this section"
  end

  helper_method :current_user, :organisation, :user_session
end
