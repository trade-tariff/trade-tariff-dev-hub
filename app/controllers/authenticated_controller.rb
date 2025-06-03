# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :require_authentication,
                :require_registration,
                :set_paper_trail_whodunnit

protected

  def require_authentication
    return unless TradeTariffDevHub.scp_enabled?

    return if user_session.present? && !user_session.expired?

    if user_session.present? && user_session.expired?
      redirect_to logout_path
    else
      redirect_to "/auth/openid_connect"
    end
  end

  def require_registration
    return unless TradeTariffDevHub.scp_enabled?

    redirect_to user_verification_steps_path if organisation.unregistered?
    redirect_to completed_user_verification_steps_path if organisation.pending?
    redirect_to rejected_user_verification_steps_path if organisation.rejected?
  end

  def user_session
    @user_session ||= Session.find_by(token: session[:token])
  end

  def organisation
    @organisation ||= current_user.organisation
  end

  def current_user
    @current_user ||= user_session.user
  end

  def organisation_id
    organisation.id
  end

  def user_id
    current_user.id
  end

  helper_method :current_user, :organisation, :user_session
end
