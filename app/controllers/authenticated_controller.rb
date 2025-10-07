# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :require_authentication,
                :set_paper_trail_whodunnit,
                :check_roles!

protected

  def require_authentication
    return unless TradeTariffDevHub.identity_authentication_enabled?
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
    @organisation ||= current_user.organisation
  end

  def current_user
    @current_user ||= if Rails.env.development?
                        User.dummy_user!
                      else
                        user_session.user
                      end
  end

  def organisation_id
    organisation.id
  end

  def user_id
    current_user.id
  end

  def check_roles!
    unless allowed?
      redirect_to root_path, alert: "Your user <strong>#{current_user&.email_address}</strong> does not have the required permissions to access this section"
    end
  end

  def allowed_roles
    ["ott:full"]
  end

  def allowed?
    allowed_roles.none? || allowed_roles.any? { |role| organisation&.has_role?(role) }
  end

  def refresh_session!
    redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true if user.nil?
  end

  helper_method :current_user, :organisation, :user_session
end
