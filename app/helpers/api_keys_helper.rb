module ApiKeysHelper
  def mask_api_key(api_key)
    return "****" if api_key.api_key_id.nil? || api_key.api_key_id.length < 5

    "****#{api_key.api_key_id[-4..]}"
  end

  def api_key_status(api_key)
    api_key.enabled ? "Active" : "Revoked on #{api_key.updated_at.strftime('%d %B %Y')}"
  end

  def creation_date(api_key)
    return "Today" if api_key.created_at.today?

    api_key.created_at.strftime("%d %B %Y")
  end
end
