module OttKeysHelper
  def mask_ott_key(ott_key)
    return "****" if ott_key.client_id.blank?

    "#{ott_key.client_id[0..3]}****#{ott_key.client_id[-4..]}"
  end

  def ott_key_status(ott_key)
    ott_key.enabled? ? "Active" : "Revoked"
  end

  def creation_date(ott_key)
    ott_key.created_at.strftime("%d %B %Y")
  end
end
