class OttKeysController < AuthenticatedController
  before_action :set_ott_key, only: %i[update revoke delete]

  def index
    @ott_keys = OttKey.where(organisation_id: organisation_id)
  end

  def new; end

  def update
    if @ott_key.enabled
      render "revoke"
    elsif deletion_enabled?
      render "delete"
    else
      raise NotImplementedError, "OTT key deletion is not implemented"
    end
  end

  def create
    # For now, use default scopes - can be enhanced later
    default_scopes = %w[read write]
    @ott_key = Ott::CreateOttKey.new.call(organisation_id, params[:ott_key_description], default_scopes)
  end

  def revoke
    Ott::RevokeOttKey.new.call(@ott_key)
    redirect_to ott_keys_path
  end

  def delete
    Ott::DeleteOttKey.new.call(@ott_key)
    redirect_to ott_keys_path
  end

private

  def set_ott_key
    @ott_key = OttKey.where(id: params[:id], organisation_id:).first
  end

  def allowed_roles
    ["ott:full"]
  end

  delegate :deletion_enabled?, to: TradeTariffDevHub
end
