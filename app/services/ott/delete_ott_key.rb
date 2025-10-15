class Ott::DeleteOttKey
  def call(ott_key)
    ott_key.destroy!
  end
end
