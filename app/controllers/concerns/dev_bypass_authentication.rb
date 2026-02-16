# frozen_string_literal: true

module DevBypassAuthentication
  extend ActiveSupport::Concern

  USER_TYPE_ADMIN = "admin"
  USER_TYPE_USER = "user"

  VALID_USER_TYPES = [USER_TYPE_ADMIN, USER_TYPE_USER].freeze

  DEV_BYPASS_ADMIN_EMAIL = "dev-admin@transformuk.com"
  DEV_BYPASS_USER_EMAIL = "dev@transformuk.com"
  DEV_BYPASS_EMAILS = [DEV_BYPASS_ADMIN_EMAIL, DEV_BYPASS_USER_EMAIL].freeze

  included do
    helper_method :dev_bypass_user_type if respond_to?(:helper_method)
  end

protected

  def dev_bypass_enabled?
    TradeTariffDevHub.dev_bypass_auth_enabled?
  end

  def dev_bypass_user_type
    return nil unless dev_bypass_enabled?

    user_type = session[:dev_bypass]
    return nil if user_type.blank?
    return nil unless VALID_USER_TYPES.include?(user_type)

    user_type
  end

  def require_dev_bypass_authentication
    return unless dev_bypass_enabled?
    return if dev_bypass_user_type.present?

    session[:return_to] = request.fullpath
    redirect_to dev_login_path
  end

  def dev_bypass_user?(user)
    DEV_BYPASS_EMAILS.include?(user&.email_address)
  end

  def find_or_create_dev_user(user_type)
    return nil unless VALID_USER_TYPES.include?(user_type)

    email = user_type == USER_TYPE_ADMIN ? DEV_BYPASS_ADMIN_EMAIL : DEV_BYPASS_USER_EMAIL
    user = User.find_or_initialize_by(email_address: email)

    # If user already exists and has an organisation, use that organisation
    # Otherwise, find or create by the default name
    org = if user.persisted? && user.organisation.present?
            user.organisation
          else
            Organisation.find_or_create_by!(organisation_name: "#{user_type.capitalize} Dev Org") do |o|
              o.description = "Dev bypass organisation"
            end
          end

    if (user_type == USER_TYPE_ADMIN) && !org.admin?
      org.assign_role!("admin")
    end
    # NOTE: Non-admin dev bypass users can exist without service roles in all environments
    # Roles must be explicitly assigned through the admin interface or role request flow

    if user.persisted?
      user.update!(organisation: org) unless user.organisation == org
    else
      user.organisation = org
      user.user_id = SecureRandom.uuid
      user.save!
    end

    user
  end

  def current_user_with_dev_bypass
    return nil unless dev_bypass_enabled?

    user_type = dev_bypass_user_type
    return nil if user_type.blank?

    find_or_create_dev_user(user_type)
  end

  def organisation_with_dev_bypass
    return nil unless dev_bypass_enabled?

    current_user_with_dev_bypass&.organisation
  end
end
