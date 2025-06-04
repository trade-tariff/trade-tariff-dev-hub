module AuthenticatedSessionsHelper
  def manage_team_url
    return if user_session.manage_team_url.blank?

    user_session.manage_team_url + "?redirect_uri=#{group_redirect_url}"
  end

  def update_profile_url
    return if user_session.update_profile_url.blank?

    user_session.update_profile_url + "?redirect_uri=#{profile_redirect_url}"
  end
end
