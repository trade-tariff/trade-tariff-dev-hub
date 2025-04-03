class ApiKeysController < ApplicationController
  before_action :set_organisation_id

  def index
    @api_keys ||= ApiKey.all
  end

  def new
  end

  def create
    @api_key = "some-api-key"
  end

  def revoke
    @api_key ||= ApiKey.find(params[:id])
    render 'revoke'
  end

  def revoke_confirm
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
