class ApiKeysController < ApplicationController
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
    @api_key.enabled = false
    @api_key.save!
    redirect_to api_keys_path
  end

  def delete
    @api_key = "some-api-key"
  end
end
