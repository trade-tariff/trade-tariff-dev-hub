# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :require_authentication,
                :require_registration,
                :set_paper_trail_whodunnit

protected

  def require_authentication
    return if current_user.present?
    return unless TradeTariffDevHub.scp_enabled?

    handle_session_expiry
    redirect_to "/auth/openid_connect"
  end

  def require_registration
    return unless TradeTariffDevHub.scp_enabled?

    redirect_to user_verification_steps_path if organisation.unregistered?
    redirect_to completed_user_verification_steps_path if organisation.pending?
    redirect_to rejected_user_verification_steps_path if organisation.rejected?
  end

  def handle_session_expiry
    return if session_expired?

    session[:user_id] = nil
    session[:organisation_id] = nil
    session[:user_profile] = nil
  end

  def user_profile
    session[:user_profile] || {}
  end

  def organisation_id
    session[:organisation_id]
  end

  def user_id
    session[:user_id]
  end

  def organisation
    @organisation ||= current_user.organisation
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def manage_team_url
    user_profile["bas:groupProfile"].to_s + "?redirect_uri=#{group_redirect_url}"
  end

  def update_profile_url
    user_profile["profile"].to_s + "?redirect_uri=#{profile_redirect_url}"
  end

  def session_expired?
    return true if session[:user_profile].blank?

    expires_at < Time.zone.now.to_i
  end

  def expires_at
    session[:user_profile]["exp"].to_i
  end

  def organisation_account?
    manage_team_url.present?
  end

  helper_method :current_user, :organisation, :manage_team_url, :update_profile_url, :organisation_account?
end
