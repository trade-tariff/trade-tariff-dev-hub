require "rails_helper"

RSpec.describe AnalyticsConsent do
  describe ".from_cookie" do
    context "when cookie is missing" do
      it "returns no selection and disallows analytics", :aggregate_failures do
        consent = described_class.from_cookie(nil)

        expect(consent.usage_choice).to be_nil
        expect(consent.analytics_allowed?).to be false
      end
    end

    context "when cookie has usage:true" do
      it "returns usage true and allows analytics", :aggregate_failures do
        consent = described_class.from_cookie({ usage: true }.to_json)

        expect(consent.usage_choice).to be true
        expect(consent.analytics_allowed?).to be true
      end
    end

    context "when cookie has usage:false" do
      it "returns usage false and disallows analytics", :aggregate_failures do
        consent = described_class.from_cookie({ usage: false }.to_json)

        expect(consent.usage_choice).to be false
        expect(consent.analytics_allowed?).to be false
      end
    end

    context "when usage key is missing" do
      it "returns no selection and disallows analytics", :aggregate_failures do
        consent = described_class.from_cookie({ remember_settings: true }.to_json)

        expect(consent.usage_choice).to be_nil
        expect(consent.analytics_allowed?).to be false
      end
    end

    context "when cookie JSON is malformed" do
      it "returns no selection and disallows analytics", :aggregate_failures do
        consent = described_class.from_cookie("{")

        expect(consent.usage_choice).to be_nil
        expect(consent.analytics_allowed?).to be false
      end
    end
  end
end
