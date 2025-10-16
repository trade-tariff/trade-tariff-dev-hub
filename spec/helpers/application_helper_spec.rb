RSpec.describe ApplicationHelper, type: :helper do
  describe "#documentation_link" do
    subject { helper.documentation_link }

    it { is_expected.to include("/fpo.html") }
    it { is_expected.to be_html_safe }
  end

  describe "#feedback_link" do
    subject { helper.feedback_link }

    it { is_expected.to include("/feedback") }
    it { is_expected.to be_html_safe }
  end

  describe "#terms_link" do
    subject { helper.terms_link }

    it { is_expected.to include("/fpo/terms-and-conditions.html") }
    it { is_expected.to be_html_safe }
  end

  describe "#created_on" do
    subject { helper.created_on(api_key) }

    let(:api_key) { create(:api_key, created_at:) }

    context "when created today" do
      let(:created_at) { Time.zone.now }

      it { is_expected.to eq("Today") }
    end

    context "when created in the past" do
      let(:created_at) { Time.zone.parse("2025-04-08T10:56:20") }

      it { is_expected.to eq("8 Apr 2025") }
    end
  end
end
