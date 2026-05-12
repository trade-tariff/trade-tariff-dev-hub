# frozen_string_literal: true

class ApiKeysController < AuthenticatedController
  include RecordOwnershipAuthorization

  before_action :set_api_key, only: %i[update revoke delete]

  def index
    @api_keys = ApiKey.where(organisation_id: organisation_id)
  end

  def new
    @api_key = ApiKey.new(organisation_id: organisation_id)
  end

  def update
    if @api_key.enabled
      render "revoke"
    else
      render "delete"
    end
  end

  def create
    description = api_key_params[:description]

    @api_key = ApiKey.new(
      organisation_id: organisation_id,
      description: description,
      enabled: true,
    )

    unless @api_key.valid?
      render :new
      return
    end

    @api_key = CreateApiKey.new.call(@api_key)
  end

  def revoke
    RevokeApiKey.new.call(@api_key)
    redirect_to redirect_path_after_action
  end

  def delete
    DeleteApiKey.new.call(@api_key)
    redirect_to redirect_path_after_action
  end

private

  def set_api_key
    @api_key = find_owned_record(ApiKey)

    unless @api_key
      redirect_to redirect_path_after_action, alert: "API key not found"
      nil
    end
  end

  def redirect_path_after_action
    redirect_path_for_owned_record(@api_key, default_path: api_keys_path)
  end

  def allowed_roles
    # Admins can access this controller (checked in AuthenticatedController#allowed?)
    # Regular users need fpo:full role
    ["fpo:full"]
  end

  def api_key_params
    params.require(:api_key).permit(:description)
  end
end
