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
end
