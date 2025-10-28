class InvitationsController < AuthenticatedController
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
        Rails.logger.debug "Invitation email sent to #{@invitation.invitee_email}"
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
    @invitation = Invitation.find_by(id: params[:id], organisation:)

    render :revoke
  end

  def update
    @invitation = Invitation.find_by(id: params[:id], organisation:)

    if @invitation.nil?
      return redirect_to organisation_path(organisation), alert: "Invitation not found."
    end

    if @invitation.pending?
      @invitation.revoked!
      redirect_to organisation_path(organisation), notice: "Invitation to #{@invitation.invitee_email} has been revoked."
    else
      redirect_to organisation_path(organisation), alert: "Invitation to #{@invitation.invitee_email} cannot be revoked as it is #{@invitation.status}."
    end
  rescue StandardError
    redirect_to organisation_path(organisation), alert: "There was a problem revoking the invitation to #{@invitation&.invitee_email}."
  end

  def resend
    @invitation = Invitation.find_by(id: params[:id], organisation:)
    @invitation.pending!
    if @invitation.send_email
      Rails.logger.debug "Invitation email resent to #{@invitation.invitee_email}"
      redirect_to organisation_path(organisation), notice: "Invitation resent to #{@invitation.invitee_email}"
    else
      Rails.logger.error "Failed to resend invitation email to #{@invitation.invitee_email}"
      redirect_to organisation_path(organisation), alert: "Failed to resend email to #{@invitation.invitee_email}"
    end
  end

private

  def invitation_params
    params.require(:invitation).permit(:invitee_email)
  end

  def allowed?
    current_user.organisation == organisation || current_user.admin?
  end
end
