class HealthcheckController < ApplicationController
  def check
    NewRelic::Agent.ignore_transaction
    render json: { git_sha1: TradeTariffDevHub.revision }, status: :ok
  end
end
