module BackLinkHelper
  def back_link_path_for_invitation(invitation)
    back_link_path_for_organisation_record(invitation, fallback_path: organisation_path(organisation))
  end

  def back_link_path_for_api_key(api_key)
    back_link_path_for_organisation_record(api_key, fallback_path: api_keys_path)
  end

private

  def back_link_path_for_organisation_record(record, fallback_path:)
    current_org = organisation

    if current_org&.admin? && record.organisation_id != current_org.id
      admin_organisation_path(record.organisation_id)
    else
      fallback_path
    end
  end
end
