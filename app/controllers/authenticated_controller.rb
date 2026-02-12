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
    # In production/staging (both use RAILS_ENV=production), use identity authentication if there's a user session
    if Rails.env.production? && authenticated?
      handle_user_session
      return
    end

    # No valid identity session - fall through to check dev bypass or redirect

    # If dev bypass is enabled and no valid identity session, show dev bypass password page
    if dev_bypass_enabled?
      require_dev_bypass_authentication
      return
    end

    # Dev bypass disabled and no valid identity session - redirect to identity service (production/staging only)
    if Rails.env.production?
      # Clear session if it exists but authentication check failed
      # (authenticated? handles cookie matching, so if it returned false, session is invalid)
      clear_authentication! if user_session.present?
      redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
    end
  end

  def authenticated?
    return false if user_session.blank?
    return false unless user_session.current?

    # Check cookie matching only if cookie is present
    # If no cookie is present, allow the session (cookie might not be set yet in callback flow)
    cookie_token = cookies[TradeTariffDevHub.id_token_cookie_name]
    return true if cookie_token.blank? # No cookie to check - allow valid session

    # If cookie is present, it must match the session
    user_session.cookie_token_match_for?(cookie_token)
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

  # Any organisation that DOES NOT have the fpo:full or admin roles needs to be redirected to the start with a flash
  # Any expired session needs to be redirected to the identity service to refresh the token
  # Any non-expired session with the fpo:full role can continue
  def handle_user_session
    if organisation&.fpo? || organisation&.admin?
      return unless user_session.renew?

      Rails.logger.info("[Auth] Session needs renewal, redirecting to identity service")
      redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
    else
      # NOTE:  Non-FPO orgs should not have an identity session - destroy it
      Rails.logger.info("[Auth] Non-FPO org detected, clearing authentication")
      clear_authentication!
      redirect_to root_path, alert: "This service is not yet open to the public. If you have any questions please contact us on hmrc-trade-tariff-support-g@digital.hmrc.gov.uk"
    end
  end

  helper_method :current_user, :organisation, :user_session
end
