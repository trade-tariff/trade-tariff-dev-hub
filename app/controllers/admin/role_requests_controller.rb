# frozen_string_literal: true

class Admin::RoleRequestsController < AuthenticatedController
  include Pagy::Backend

  before_action :ensure_role_request_enabled
  before_action :ensure_admin
  before_action :set_role_request, only: %i[approve reject]

  def index
    @pagy, @role_requests = pagy(
      RoleRequest.pending
                  .includes(:organisation, :user)
                  .order(created_at: :desc),
      page: params[:page],
      items: 20,
    )
  end

  def approve
    @role_request.approve!(approved_by: current_user)
    if send_approval_email
      redirect_to admin_role_requests_path, notice: "Role #{@role_request.role_name} has been assigned to #{@role_request.organisation.organisation_name}"
    else
      Rails.logger.error "Failed to send approval email for role request #{@role_request.id} to #{@role_request.user.email_address}"
      redirect_to admin_role_requests_path, alert: "Role #{@role_request.role_name} has been assigned to #{@role_request.organisation.organisation_name}, but we failed to send the notification email."
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    Rails.logger.error("Error approving role request: #{e.class} - #{e.message}")
    redirect_to admin_role_requests_path, alert: "There was a problem approving the role request: #{e.message}"
  rescue StandardError => e
    Rails.logger.error("Unexpected error approving role request: #{e.class} - #{e.message}")
    redirect_to admin_role_requests_path, alert: "There was an unexpected problem approving the role request. Please try again."
  end

  def reject
    @role_request.reject!(rejected_by: current_user)
    if send_rejection_email
      redirect_to admin_role_requests_path, notice: "Role request for #{@role_request.role_name} from #{@role_request.organisation.organisation_name} has been rejected"
    else
      Rails.logger.error "Failed to send rejection email for role request #{@role_request.id} to #{@role_request.user.email_address}"
      redirect_to admin_role_requests_path, alert: "Role request for #{@role_request.role_name} from #{@role_request.organisation.organisation_name} has been rejected, but we failed to send the notification email."
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    Rails.logger.error("Error rejecting role request: #{e.class} - #{e.message}")
    redirect_to admin_role_requests_path, alert: "There was a problem rejecting the role request: #{e.message}"
  rescue StandardError => e
    Rails.logger.error("Unexpected error rejecting role request: #{e.class} - #{e.message}")
    redirect_to admin_role_requests_path, alert: "There was an unexpected problem rejecting the role request. Please try again."
  end

private

  def ensure_role_request_enabled
    return if TradeTariffDevHub.role_request_enabled?

    redirect_to root_path, alert: "This feature is currently disabled."
  end

  def ensure_admin
    redirect_to root_path, alert: "Access denied" unless organisation.admin?
  end

  def set_role_request
    @role_request = RoleRequest.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_role_requests_path, alert: "Role request not found"
  end

  def send_approval_email
    # Build notification to validate it can be constructed (catches errors early)
    notification = Notification.build_for_role_request_approved(@role_request)
    # In development, validate notification can be built but don't actually send
    return true if Rails.env.development?

    SendNotification.new(notification).call
  end

  def send_rejection_email
    # Build notification to validate it can be constructed (catches errors early)
    notification = Notification.build_for_role_request_rejected(@role_request)
    # In development, validate notification can be built but don't actually send
    return true if Rails.env.development?

    SendNotification.new(notification).call
  end
end
