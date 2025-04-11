class ApiKeysController < ApplicationController
  before_action :set_organisation_id

  def index
    @api_keys ||= ApiKey.all
  end

  def new
  end

  def show
    if params[:success]
      render 'create'
    else
      redirect_to not_found_path
    end
  end

  def update
    @api_key ||= ApiKey.find(params[:id])
    if @api_key.enabled
      render 'revoke'
    else
      render 'delete'
    end
  end

  def create
    @api_key = CreateApiKey.new.call(params[:organisation_id], params[:api_key_description])
    session[:api_key_id] = @api_key.api_key_id
    redirect_to api_keys_show_path(success: true)
  end

  def revoke
    @api_key ||= ApiKey.find(params[:id])
    RevokeApiKey.new.call(@api_key)
    redirect_to api_keys_path
  end

  def delete
    @api_key ||= ApiKey.find(params[:id])
    DeleteApiKey.new.call(@api_key)
    redirect_to api_keys_path
  end
end
