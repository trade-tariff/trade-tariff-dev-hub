# frozen_string_literal: true

class RoleRequestsController < AuthenticatedController
  before_action :ensure_not_admin
  before_action :ensure_own_organisation
  before_action :set_available_roles

  def new
    @role_request = RoleRequest.new
    @available_roles = available_roles_for_request
  end

  def create
    @role_request = RoleRequest.new(
      role_name: role_request_params[:role_name],
      note: role_request_params[:note],
      organisation: organisation,
      user: current_user,
    )

    if @role_request.save
      if send_role_request_email
        redirect_to organisation_path(organisation), notice: "Your access request has been submitted successfully"
      else
        Rails.logger.error "Failed to send role request email for role #{@role_request.role_name} from #{@role_request.user.email_address}"
        redirect_to organisation_path(organisation), alert: "Your access request has been submitted, but we failed to send the notification email. Please contact support if you don't receive a response."
      end
    else
      @available_roles = available_roles_for_request
      render :new
    end
  end

private

  def ensure_not_admin
    redirect_to organisation_path(organisation), alert: "Admins already have access to all roles" if organisation.admin?
  end

  def set_available_roles
    @available_roles = available_roles_for_request
    redirect_to organisation_path(organisation), alert: "No additional roles available to request." if @available_roles.empty?
  end

  def available_roles_for_request
    available_role_names = organisation.available_service_roles.pluck(:name)
    pending_role_names = organisation.role_requests.pending.pluck(:role_name)
    available_role_names -= pending_role_names
    # Return empty relation if no roles available (Role.where(name: []) returns empty relation)
    return Role.none if available_role_names.empty?

    Role.where(name: available_role_names).order(:name)
  end

  def ensure_own_organisation
    # Prevent admins from requesting roles for assumed organisations
    # Non-admin users will always have organisation == current_user.organisation
    return if organisation == current_user.organisation

    redirect_to organisation_path(current_user.organisation), alert: "You can only request access for your own organisation"
  end

  def role_request_params
    params.require(:role_request).permit(:role_name, :note)
  end

  def send_role_request_email
    # Build notification to validate it can be constructed (catches errors early)
    notification = Notification.build_for_role_request(@role_request)
    # In development, validate notification can be built but don't actually send
    return true if Rails.env.development?

    SendNotification.new(notification).call
  end
end
