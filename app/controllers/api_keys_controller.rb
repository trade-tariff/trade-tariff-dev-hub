# frozen_string_literal: true

class ApiKeysController < AuthenticatedController
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
    elsif deletion_enabled?
      render "delete"
    else
      raise NotImplementedError, "API key deletion is not implemented"
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
    @api_key = if organisation&.admin?
                 # Admins can access any API key
                 ApiKey.find_by(id: params[:id])
               else
                 # Regular users can only access their organisation's keys
                 ApiKey.where(id: params[:id], organisation_id:).first
               end

    unless @api_key
      redirect_to redirect_path_after_action, alert: "API key not found"
      nil
    end
  end

  def redirect_path_after_action
    # If user is an admin and the API key belongs to a different organisation,
    # redirect to that organisation's admin page
    if organisation&.admin? && @api_key && @api_key.organisation_id != organisation.id
      admin_organisation_path(@api_key.organisation_id)
    else
      api_keys_path
    end
  end

  def allowed_roles
    # Admins can access this controller (checked in AuthenticatedController#allowed?)
    # Regular users need fpo:full role
    ["fpo:full"]
  end

  def api_key_params
    params.require(:api_key).permit(:description)
  end

  delegate :deletion_enabled?, to: TradeTariffDevHub
end
