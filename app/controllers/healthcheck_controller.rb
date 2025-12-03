class HealthcheckController < ApplicationController
  def check
    NewRelic::Agent.ignore_transaction
    render json: { status: "ok" }, status: :ok
  end

  def checkz
    NewRelic::Agent.ignore_transaction
    render json: { status: "ok" }, status: :ok
  end
end
