# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  include SessionAuthentication

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
    # Check for identity authentication first (works in all environments)
    if authenticated?
      handle_user_session
      return
    end

    # No valid identity session - clear any invalid session before redirecting to Identity.
    # (authenticated? handles cookie matching, so if it returned false, session is invalid)
    clear_authentication! if user_session.present?

    redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
  end

  def organisation
    @organisation ||= if user_session&.assumed_organisation_id.present?
                        user_session.assumed_organisation
                      elsif user_session&.user.present?
                        user_session.user.organisation
                      end
  end

  def current_user
    @current_user ||= user_session&.user
  end

  def organisation_id
    organisation&.id
  end

  def user_id
    current_user&.id
  end

  def check_roles!
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

  def disallowed_redirect!
    redirect_to root_path, alert: "Your user <strong>#{current_user&.email_address}</strong> does not have the required permissions to access this section"
  end

  # Any organisation that DOES NOT have the fpo:full, trade_tariff:full, or admin roles needs to be redirected to the start with a flash
  # Any expired session needs to be redirected to the identity service to refresh the token
  # Any non-expired session with one of the allowed roles can continue
  def handle_user_session
    unless TradeTariffDevHub.block_non_fpo_identity_sessions_in_production?
      renew_identity_session_if_needed
      return
    end

    if organisation&.fpo? || organisation&.admin? || organisation&.trade_tariff_access?
      renew_identity_session_if_needed
    else
      Rails.logger.info("[Auth] Non-permitted org detected, clearing authentication")
      clear_authentication!
      redirect_to root_path, alert: "This service is not yet open to the public. If you have any questions please contact us on hmrc-trade-tariff-support-g@digital.hmrc.gov.uk"
    end
  end

  def renew_identity_session_if_needed
    return unless user_session.renew?

    Rails.logger.info("[Auth] Session needs renewal, redirecting to identity service")
    redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true
  end

  helper_method :current_user, :organisation, :user_session
end
