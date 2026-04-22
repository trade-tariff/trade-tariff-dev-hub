RSpec.describe AnalyticsHelper, type: :helper do
  describe "#analytics_allowed?" do
    context "when consent cookie has not been set" do
      it { expect(helper.analytics_allowed?).to be false }
    end

    context "when consent cookie has been set" do
      before do
        allow(controller.cookies).to receive(:[]).with("cookies_policy").and_return(value)
      end

      context "when cookies have been accepted" do
        let(:value) { { usage: true, remember_settings: true }.to_json.to_s }

        it { expect(helper.analytics_allowed?).to be true }
      end

      context "when cookies have been rejected" do
        let(:value) { { usage: false, remember_settings: true }.to_json.to_s }

        it { expect(helper.analytics_allowed?).to be false }
      end

      context "when usage key is missing" do
        let(:value) { { remember_settings: true }.to_json.to_s }

        it { expect(helper.analytics_allowed?).to be false }
      end

      context "when usage is explicitly null" do
        let(:value) { { usage: nil, remember_settings: true }.to_json.to_s }

        it { expect(helper.analytics_allowed?).to be false }
      end

      context "when the cookie contains malformed JSON" do
        let(:value) { "not-json" }

        it { expect(helper.analytics_allowed?).to be false }
      end
    end
  end
end
