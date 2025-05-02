# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :require_authentication,
                :require_registration,
                :set_paper_trail_whodunnit

  def require_authentication
    return if current_user.present?
    return unless TradeTariffDevHub.scp_enabled?

    redirect_to "/auth/openid_connect"
  end

  def require_registration
    return unless TradeTariffDevHub.scp_enabled?

    redirect_to user_verification_steps_path if organisation.unregistered?
    redirect_to completed_user_verification_steps_path if organisation.pending?
    redirect_to rejected_user_verification_steps_path if organisation.rejected?
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

  helper_method :current_user, :organisation, :manage_team_url, :update_profile_url
end
