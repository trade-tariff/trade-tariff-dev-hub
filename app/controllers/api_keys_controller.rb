class ApiKeysController < ApplicationController
  def index
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
