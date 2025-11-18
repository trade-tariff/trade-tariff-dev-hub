class Ott::RevokeOttKey
  def call(ott_key)
    ott_key.revoke!
  end
end
