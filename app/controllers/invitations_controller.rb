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
      redirect_to organisation_path(organisation), notice: "Invitation sent to #{@invitation.invitee_email}"
    else
      render :new
    end
  end

  def revoke
    @invitation = Invitation.find_by(id: params[:id], organisation:)
  end

  def destroy
    @invitation = Invitation.find_by(id: params[:id], organisation:)

    @invitation.revoked!

    redirect_to organisation_path(organisation), notice: "Invitation to #{@invitation.invitee_email} has been revoked."
  rescue StandardError
    redirect_to organisation_path(organisation), alert: "There was a problem revoking the invitation to #{@invitation&.invitee_email}."
  end

  # TODO: implement resend action
  def resend
    @invitation = Invitation.find_by(id: params[:id], organisation:)
    @invitation.pending!
    redirect_to organisation_path(organisation), notice: "Invitation resent to #{@invitation.invitee_email}"
  end

private

  def invitation_params
    params.require(:invitation).permit(:invitee_email)
  end

  def allowed?
    current_user.organisation == organisation
  end

  def organisation
    if current_user.admin?
      @organisation ||= Organisation.find_by(id: params[:id])
    else
      super
    end
  end
end
