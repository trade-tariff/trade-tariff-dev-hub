module ApiKeysHelper
  def mask_api_key(api_key)
    api_key_id = api_key.api_key_id

    return "****" if api_key_id.nil? || api_key_id.length < 5

    "****#{api_key_id[-4..]}"
  end

  def api_key_status(api_key)
    api_key.enabled ? "Active" : "Revoked"
  end
end
