class Admin::OrganisationRolesController < AuthenticatedController
  before_action :ensure_admin
  before_action :set_organisation
  before_action :validate_role_name

  def create
    @organisation.assign_role!(role_name)
    redirect_to admin_organisation_path(@organisation), notice: "Role #{role_name} added"
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    redirect_to admin_organisation_path(@organisation), alert: e.message
  end

  def destroy
    unless @organisation.can_remove_role?(role_name)
      message = removal_block_message(role_name)
      redirect_to admin_organisation_path(@organisation), alert: message
      return
    end

    @organisation.unassign_role!(role_name)
    redirect_to admin_organisation_path(@organisation), notice: "Role #{role_name} removed"
  rescue ActiveRecord::RecordNotFound => e
    redirect_to admin_organisation_path(@organisation), alert: e.message
  end

private

  def ensure_admin
    redirect_to root_path, alert: "Access denied" unless organisation.admin?
  end

  def set_organisation
    @organisation = Organisation.find(params[:organisation_id])
  end

  def validate_role_name
    return if Role.assignable_names.include?(role_name)

    redirect_to admin_organisation_path(@organisation), alert: "Invalid role"
  end

  def role_name
    params.require(:role_name)
  end

  def removal_block_message(role_name)
    case @organisation.remove_role_block_reason(role_name)
    when :admin_role
      "Cannot remove admin role"
    when :trade_tariff_keys
      "Cannot remove role while organisation has Trade Tariff keys"
    when :active_api_keys
      "Cannot remove role while organisation has active FPO API keys"
    else
      "Cannot remove role"
    end
  end
end
