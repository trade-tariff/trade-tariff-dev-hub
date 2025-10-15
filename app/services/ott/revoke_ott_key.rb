class Ott::RevokeOttKey
  def call(ott_key)
    ott_key.update!(enabled: false)
    ott_key
  end
end
