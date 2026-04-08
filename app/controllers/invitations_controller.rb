class InvitationsController < AuthenticatedController
  include RecordOwnershipAuthorization

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
        redirect_to organisation_path(organisation), notice: { heading: "Invitation sent" }
      else
        Rails.logger.error "Failed to send invitation email to #{@invitation.invitee_email}"
        redirect_to organisation_path(organisation), alert: {
          heading: "We could not send the invitation",
          body: "Try again later.",
        }
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
      redirect_to redirect_path_after_action, notice: { heading: "Invitation revoked" }
    else
      redirect_to redirect_path_after_action, alert: "Only pending invitations can be revoked."
    end
  rescue StandardError => e
    Rails.logger.error("Error revoking invitation: #{e.class} - #{e.message}")
    redirect_to redirect_path_after_action, alert: {
      heading: "We could not revoke the invitation",
      body: "Try again later.",
    }
  end

  def resend
    if @invitation.nil?
      redirect_to redirect_path_after_action, alert: "Invitation not found."
    elsif !@invitation.pending?
      redirect_to redirect_path_after_action, alert: "Only pending invitations can be resent."
    elsif @invitation.send_email
      redirect_to redirect_path_after_action, notice: { heading: "Invitation resent" }
    else
      Rails.logger.error "Failed to resend invitation email to #{@invitation.invitee_email}"
      redirect_to redirect_path_after_action, alert: {
        heading: "We could not resend the invitation",
        body: "Try again later.",
      }
    end
  end

  def delete
    if @invitation.nil?
      redirect_to redirect_path_after_action, alert: "Invitation not found."
    elsif @invitation.revoked?
      @invitation.destroy!
      redirect_to redirect_path_after_action, notice: { heading: "Invitation deleted" }
    else
      redirect_to redirect_path_after_action, alert: "Only revoked invitations can be deleted."
    end
  end

private

  def set_invitation
    @invitation = find_owned_record(Invitation)

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
    redirect_path_for_owned_record(@invitation, default_path: organisation_path(organisation))
  end

  def invitation_params
    params.require(:invitation).permit(:invitee_email)
  end

  def allowed?
    current_user.organisation == organisation || current_user.admin?
  end
end
