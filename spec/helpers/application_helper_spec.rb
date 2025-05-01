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

  describe "#fpo_usage_terms" do
    subject(:terms) { helper.fpo_usage_terms }

    it { is_expected.to all(be_a(Struct)) }
    it { is_expected.to all(respond_to(:id, :text)) }

    it "translates the terms correctly" do
      expect(terms.map(&:text).first).to include("designated for backend operations only")
    end
  end

  describe "#user_verification_steps_review_answers_terms_hint" do
    subject { helper.user_verification_steps_review_answers_terms_hint }

    it { is_expected.to include("Read the information below carefully") }
    it { is_expected.to be_html_safe }
  end
end
