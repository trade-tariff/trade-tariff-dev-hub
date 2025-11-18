class InvitationsController < AuthenticatedController
  before_action :set_invitation, only: %i[edit update resend delete]

  def new
    @invitation = Invitation.new
  end

  def create
    @invitation = Invitation.new(
      invitee_email: invitation_params[:invitee_email],
      organisation: organisation,
      user: current_user,
    )

    if @invitation.save
      if @invitation.send_email
        redirect_to organisation_path(organisation), notice: "Invitation sent to #{@invitation.invitee_email}"
      else
        Rails.logger.error "Failed to send invitation email to #{@invitation.invitee_email}"
        redirect_to organisation_path(organisation), alert: "Failed to send email to #{@invitation.invitee_email}. Please try again later."
      end
    else
      render :new
    end
  end

  def edit
    if @invitation.nil?
      return redirect_to redirect_path_after_action, alert: "Invitation not found."
    end

    render :revoke
  end

  def update
    if @invitation.nil?
      return redirect_to redirect_path_after_action, alert: "Invitation not found."
    end

    # GET/HEAD request: render confirmation page (revoke or delete)
    if request.get? || request.head?
      # If on delete route and invitation is pending, redirect (can't delete pending invitations)
      if request.path.include?("/delete") && @invitation.pending?
        redirect_to redirect_path_after_action, alert: "Invalid invitation state."
        return
      end

      if @invitation.pending?
        render :revoke
      elsif @invitation.revoked?
        render :delete
      else
        redirect_to redirect_path_after_action, alert: "Invalid invitation state."
      end
      return
    end

    # PATCH request: perform revocation
    if @invitation.pending?
      @invitation.revoked!
      redirect_to redirect_path_after_action, notice: "Invitation to #{@invitation.invitee_email} has been revoked."
    else
      redirect_to redirect_path_after_action, alert: "Invitation to #{@invitation.invitee_email} cannot be revoked as it is #{@invitation.status}."
    end
  rescue StandardError => e
    Rails.logger.error("Error revoking invitation: #{e.class} - #{e.message}")
    redirect_to redirect_path_after_action, alert: "There was a problem revoking the invitation to #{@invitation&.invitee_email}."
  end

  def resend
    if @invitation.nil?
      redirect_to redirect_path_after_action, alert: "Invitation not found."
    elsif !@invitation.pending?
      redirect_to redirect_path_after_action, alert: "Only pending invitations can be resent."
    elsif @invitation.send_email
      redirect_to redirect_path_after_action, notice: "Invitation resent to #{@invitation.invitee_email}"
    else
      Rails.logger.error "Failed to resend invitation email to #{@invitation.invitee_email}"
      redirect_to redirect_path_after_action, alert: "Failed to resend email to #{@invitation.invitee_email}"
    end
  end

  def delete
    if @invitation.nil?
      redirect_to redirect_path_after_action, alert: "Invitation not found."
    elsif @invitation.revoked?
      invitee = @invitation.invitee_email
      @invitation.destroy!
      redirect_to redirect_path_after_action, notice: "Invitation for #{invitee} has been deleted."
    else
      redirect_to redirect_path_after_action, alert: "Only revoked invitations can be deleted."
    end
  end

private

  def set_invitation
    @invitation = if organisation&.admin?
                    # Admins can access any invitation
                    Invitation.find_by(id: params[:id])
                  else
                    # Regular users can only access their organisation's invitations
                    Invitation.find_by(id: params[:id], organisation:)
                  end

    unless @invitation
      redirect_to redirect_path_after_action, alert: "Invitation not found."
      nil
    end
  rescue StandardError => e
    Rails.logger.error("Error setting invitation: #{e.class} - #{e.message}")
    redirect_to redirect_path_after_action, alert: "Invitation not found."
    nil
  end

  def redirect_path_after_action
    # If user is an admin and the invitation belongs to a different organisation,
    # redirect to that organisation's admin page
    if @invitation && organisation&.admin? && @invitation.organisation_id != organisation.id
      admin_organisation_path(@invitation.organisation_id)
    else
      organisation_path(organisation)
    end
  end

  def invitation_params
    params.require(:invitation).permit(:invitee_email)
  end

  def allowed?
    current_user.organisation == organisation || current_user.admin?
  end
end
