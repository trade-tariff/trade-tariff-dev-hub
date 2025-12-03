class HealthcheckController < ApplicationController
  def check
    NewRelic::Agent.ignore_transaction
    render json: { git_sha1: CURRENT_REVISION }
  end

  def checkz
    NewRelic::Agent.ignore_transaction
    render json: { git_sha1: CURRENT_REVISION }
  end
end
