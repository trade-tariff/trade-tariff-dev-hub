class HomepageController < ApplicationController
  def index
    # Homepage shows normally - redirect happens when user clicks "Start now"
    # which goes to api_keys_path and triggers AuthenticatedController#require_authentication
  end

protected

  def current_user
    @current_user ||= if TradeTariffDevHub.dev_bypass_auth_enabled?
                        # Only return user if dev bypass session exists
                        session[:dev_bypass].present? ? find_or_create_dev_user(session[:dev_bypass]) : nil
                      else
                        # Use normal session authentication
                        Session.find_by(token: session[:token])&.user
                      end
  end

  def organisation
    @organisation ||= current_user&.organisation
  end

  def find_or_create_dev_user(user_type)
    email = user_type == "admin" ? "dev-admin@transformuk.com" : "dev@transformuk.com"
    user = User.find_or_initialize_by(email_address: email)

    unless user.persisted?
      org = Organisation.find_or_create_by!(organisation_name: "#{user_type.capitalize} Dev Org") do |o|
        o.description = "Dev bypass organisation"
      end

      if user_type == "admin"
        org.assign_role!("admin") unless org.admin?
      else
        org.assign_role!("ott:full") unless org.has_role?("ott:full")
        org.assign_role!("fpo:full") unless org.has_role?("fpo:full")
      end

      user.organisation = org
      user.user_id = SecureRandom.uuid
      user.save!
    end

    user
  end

  helper_method :current_user, :organisation
end
