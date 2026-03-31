class AssociateUserToOrganisation
  class InvitationRequiredError < StandardError
  end

  def call(user)
    return if user.organisation.present?

    invitation = find_pending_invitation(user)

    unless invitation
      return create_and_associate_self_service_organisation(user) if TradeTariffDevHub.allow_passwordless_self_service_org_creation?

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

  def create_and_associate_self_service_organisation(user)
    User.transaction do
      user.organisation = Organisation.create!(
        organisation_name: user.email_address,
        description: "Self-service organisation for #{user.email_address}",
      )
      user.save!
    end
  end
end
