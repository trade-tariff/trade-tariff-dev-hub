class Ott::RevokeOttKey
  def call(ott_key)
    ott_key.destroy!
  end
end
