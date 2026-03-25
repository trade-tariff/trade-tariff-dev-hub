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

    before do
      allow(NewRelic::Agent).to receive(:notice_error)
    end

    it "accepts a CSP report without a CSRF token", :aggregate_failures do
      post "/csp-violation-report",
           params: payload,
           headers: {
             "CONTENT_TYPE" => "application/csp-report",
             "ACCEPT" => "application/json",
           }

      expect(response).to have_http_status(:ok)
      expect(NewRelic::Agent).to have_received(:notice_error).with("CSP Violation: #{payload}")
    end
  end
end
