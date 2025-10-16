# frozen_string_literal: true

class ApiKeysController < AuthenticatedController
  before_action :set_api_key, only: %i[update revoke delete]

  def index
    @api_keys = ApiKey.where(organisation_id: organisation_id)
  end

  def new; end

  def update
    if @api_key.enabled
      render "revoke"
    elsif deletion_enabled?
      render "delete"
    else
      raise NotImplementedError, "API key deletion is not implemented"
    end
  end

  def create
    @api_key = CreateApiKey.new.call(organisation_id, params[:api_key_description])
  end

  def revoke
    RevokeApiKey.new.call(@api_key)
    redirect_to api_keys_path
  end

  def delete
    DeleteApiKey.new.call(@api_key)
    redirect_to api_keys_path
  end

private

  def set_api_key
    @api_key = ApiKey.where(id: params[:id], organisation_id:).first
  end

  def allowed_roles
    ["fpo:full"]
  end

  delegate :deletion_enabled?, to: TradeTariffDevHub
end
