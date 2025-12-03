# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :require_authentication,
                :set_paper_trail_whodunnit,
                :check_roles!
  before_action :add_nr_custom_attributes

private

  def add_nr_custom_attributes
    NewRelic::Agent.add_custom_attributes(
      org_id: organisation&.id,
      client_id: current_user&.id,
    )
  end

protected

  def require_authentication
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
    @organisation ||= if Rails.env.development?
                        # In development, use current_user's organisation directly
                        current_user&.organisation
                      elsif user_session&.assumed_organisation_id.present?
                        user_session.assumed_organisation
                      else
                        current_user&.organisation
                      end
  end

  def current_user
    @current_user ||= if Rails.env.development?
                        # Allow switching between users in development via session
                        session[:dev_user_email] ||= "dev@transformuk.com"
                        User.find_by(email_address: session[:dev_user_email]) || User.dummy_user!
                      else
                        user_session&.user
                      end
  end

  def organisation_id
    organisation.id
  end

  def user_id
    current_user&.id
  end

  def check_roles!
    disallowed_redirect! unless allowed?
  end

  def allowed_roles
    ["trade_tariff:full"]
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

  helper_method :current_user, :organisation, :user_session
end
