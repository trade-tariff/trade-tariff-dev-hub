class ApiKeysController < ApplicationController
  before_action :set_organisation_id
  before_action :set_api_key_id, only: %i[update revoke delete]

  def index
    @api_keys = ApiKey.all
  end

  def new; end

  def show
    if params[:success]
      render "create"
    else
      redirect_to not_found_path
    end
  end

  def update
    if @api_key.enabled
      render "revoke"
    else
      render "delete"
    end
  end

  def create
    @api_key = CreateApiKey.new.call(params[:organisation_id], params[:api_key_description])
    session[:api_key_id] = @api_key.api_key_id
    redirect_to api_keys_show_path(success: true)
  end

  def revoke
    RevokeApiKey.new.call(@api_key)
    redirect_to api_keys_path
  end

  def delete
    DeleteApiKey.new.call(@api_key)
    redirect_to api_keys_path
  end
end
