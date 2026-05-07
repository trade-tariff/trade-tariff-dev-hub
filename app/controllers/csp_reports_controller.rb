class CspReportsController < ActionController::API
  def create
    Rails.logger.warn("CSP Violation: #{request.raw_post}")

    head :no_content
  end
end
