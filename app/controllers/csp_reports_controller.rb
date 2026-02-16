class CspReportsController < ApplicationController
  def create
    Rails.logger.warn "CSP Violation: #{request.body.read}"
    NewRelic::Agent.notice_error("CSP Violation: #{request.body.read}")
    head :ok
  end
end
