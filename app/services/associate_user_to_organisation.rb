class AssociateUserToOrganisation
  class InvitationRequiredError < StandardError
  end

  def call(user)
    return if user.organisation.present?

    invitation = find_pending_invitation(user)

    unless invitation
      raise InvitationRequiredError, "No pending invitation found for #{user.email_address}"
    end

    associate_via_invitation(user, invitation)
  end

private

  def find_pending_invitation(user)
    Invitation.find_by(
      invitee_email: user.email_address,
      status: :pending,
    )
  end

  def associate_via_invitation(user, invitation)
    User.transaction do
      user.organisation = invitation.organisation
      invitation.accepted!
      user.save!
    end
  end
end
