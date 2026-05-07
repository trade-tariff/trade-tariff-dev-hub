RSpec.describe "CspReports", type: :request do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  describe "POST /csp-violation-report" do
    let(:payload) { '{"csp-report":{"document-uri":"https://example.com"}}' }

    it "accepts a CSP report without a CSRF token" do
      post "/csp-violation-report",
           params: payload,
           headers: {
             "CONTENT_TYPE" => "application/csp-report",
             "ACCEPT" => "application/json",
           }

      expect(response).to have_http_status(:no_content)
    end

    it "logs the CSP violation" do
      allow(Rails.logger).to receive(:warn)

      post "/csp-violation-report",
           params: payload,
           headers: {
             "CONTENT_TYPE" => "application/csp-report",
             "ACCEPT" => "application/json",
           }

      expect(Rails.logger).to have_received(:warn).with("CSP Violation: #{payload}")
    end
  end
end
