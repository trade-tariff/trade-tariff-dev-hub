class CspReportsController < ActionController::API
  def create
    payload = request.raw_post

    Rails.logger.warn("CSP Violation: #{payload}")
    NewRelic::Agent.notice_error("CSP Violation: #{payload}")

    head :ok
  end
end
