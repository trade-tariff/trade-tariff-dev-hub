class ApiKeysController < ApplicationController
  before_action :set_organisation_id

  def index
    @api_keys ||= ApiKey.all
  end

  def update
    @api_key ||= ApiKey.find(params[:id])
    if @api_key.enabled
      render 'revoke'
    else
      render 'delete'
    end
  end

  def new
  end

  def create
    @api_key = "some-api-key"
  end

  def revoke
    @api_key ||= ApiKey.find(params[:id])
    RevokeApiKey.new.call(@api_key)
    redirect_to api_keys_path
  end

  def delete
    @api_key ||= ApiKey.find(params[:id])
    render 'delete'
  end

  def delete_confirm
    @api_key ||= ApiKey.find(params[:id])
    DeleteApiKey.new.call(@api_key)
    redirect_to api_keys_path
  end
end
