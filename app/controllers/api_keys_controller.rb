class ApiKeysController < AuthenticatedController
  before_action :set_api_key, only: %i[update revoke delete]

  def index
    @api_keys = ApiKey.where(organisation_id: organisation_id)
  end

  def new; end

  def update
    if @api_key.enabled
      render "revoke"
    else
      render "delete"
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
    @api_key = ApiKey.find(params[:id])
  end
end
