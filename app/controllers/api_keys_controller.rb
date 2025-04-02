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
    @api_key = "some-api-key"
  end

  def delete
    @api_key = "some-api-key"
  end
end
