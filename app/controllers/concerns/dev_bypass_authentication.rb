# frozen_string_literal: true

module DevBypassAuthentication
  extend ActiveSupport::Concern

  USER_TYPE_ADMIN = "admin"
  USER_TYPE_USER = "user"

  VALID_USER_TYPES = [USER_TYPE_ADMIN, USER_TYPE_USER].freeze

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

  def find_or_create_dev_user(user_type)
    return nil unless VALID_USER_TYPES.include?(user_type)

    email = user_type == USER_TYPE_ADMIN ? "dev-admin@transformuk.com" : "dev@transformuk.com"
    user = User.find_or_initialize_by(email_address: email)

    org = Organisation.find_or_create_by!(organisation_name: "#{user_type.capitalize} Dev Org") do |o|
      o.description = "Dev bypass organisation"
    end

    if user_type == USER_TYPE_ADMIN
      org.assign_role!("admin") unless org.admin?
    else
      org.assign_role!("trade_tariff:full") unless org.has_role?("trade_tariff:full")
      org.assign_role!("fpo:full") unless org.has_role?("fpo:full")
    end

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
