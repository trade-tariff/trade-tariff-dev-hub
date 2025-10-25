class OttKeysController < AuthenticatedController
  before_action :set_ott_key, only: %i[update revoke delete]

  def index
    @ott_keys = if TradeTariffDevHub.identity_authentication_enabled?
                  OttKey.where(organisation_id: organisation_id)
                else
                  # For development when authentication is disabled, show all OTT keys
                  OttKey.all
                end
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
    org_id = if TradeTariffDevHub.identity_authentication_enabled?
               organisation_id
             else
               # For development when authentication is disabled, use a default organisation
               Organisation.first&.id || create_default_organisation.id
             end

    # For now, use default scopes - can be enhanced later
    default_scopes = %w[read write]
    @ott_key = Ott::CreateOttKey.new.call(org_id, params[:ott_key_description], default_scopes)
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
    @ott_key = if TradeTariffDevHub.identity_authentication_enabled?
                 OttKey.where(id: params[:id], organisation_id:).first
               else
                 # For development when authentication is disabled, find by ID only
                 OttKey.find(params[:id])
               end
  end

  delegate :deletion_enabled?, to: TradeTariffDevHub

  def create_default_organisation
    Organisation.find_or_create_by(organisation_id: "DEV_ORG_#{SecureRandom.hex(8)}") do |org|
      org.organisation_name = "Development Organisation"
      org.description = "Default organisation for development when SCP is disabled"
      org.status = :authorised
    end
  end
end
