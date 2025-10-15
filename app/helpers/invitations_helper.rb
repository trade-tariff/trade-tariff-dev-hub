module InvitationsHelper
  STATUS_TAG_COLOURS = {
    "Accepted" => "green",
    "Pending" => "blue",
    "Revoked" => "grey",
  }.freeze

  def invitation_status(invitation)
    status = invitation.status.titleize
    colour = STATUS_TAG_COLOURS[status] || "grey"
    govuk_tag(text: status, colour: colour)
  end

  def invitation_actions_for(invitation)
    actions = []

    if invitation.pending?
      actions << govuk_link_to("Resend", resend_invitation_path(invitation), no_visited_state: true)
      actions << govuk_link_to("Revoke", edit_invitation_path(invitation), no_visited_state: true)
    elsif invitation.revoked?
      actions << link_to("Delete", delete_invitation_path(invitation), class: "govuk-link govuk-link--warning")
    end

    return content_tag(:span, "No actions available", class: "govuk-hint govuk-!-margin-0") if actions.empty?

    safe_join(actions, tag.br)
  end
end
