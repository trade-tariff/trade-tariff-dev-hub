RSpec.describe AuthenticatedSessionsHelper, type: :helper do
  describe "#manage_team_url" do
    subject(:url) { helper.manage_team_url }

    let(:user_session) { build(:session, raw_info: { "bas:groupProfile" => manage_team_url }) }

    before do
      allow(helper).to receive(:user_session).and_return(user_session)
    end

    context "when manage_team_url is present" do
      let(:manage_team_url) { "https://example.com/my/group/profile" }

      it { is_expected.to eq("https://example.com/my/group/profile?redirect_uri=#{group_redirect_url}") }
    end

    context "when manage_team_url is blank" do
      let(:manage_team_url) { "" }

      it { is_expected.to be_nil }
    end
  end

  describe "#update_profile_url" do
    subject(:url) { helper.update_profile_url }

    let(:user_session) { build(:session, raw_info: { "profile" => update_profile_url }) }

    before do
      allow(helper).to receive(:user_session).and_return(user_session)
    end

    context "when update_profile_url is present" do
      let(:update_profile_url) { "https://example.com/my/profile/update" }

      it { is_expected.to eq("https://example.com/my/profile/update?redirect_uri=#{profile_redirect_url}") }
    end

    context "when update_profile_url is blank" do
      let(:update_profile_url) { "" }

      it { is_expected.to be_nil }
    end
  end
end
