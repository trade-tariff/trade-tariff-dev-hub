# == Schema Information
#
# Table name: sessions
#
#  id         :uuid             not null, primary key
#  token      :string           not null
#  user_id    :uuid             not null
#  raw_info   :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  expires_at :datetime
#  id_token   :text             not null
#
# Indexes
#
#  index_sessions_on_token    (token) UNIQUE
#  index_sessions_on_user_id  (user_id)
#

RSpec.describe Session, type: :model do
  describe "validations" do
    subject(:session) { build(:session) }

    it { is_expected.to validate_presence_of(:id_token) }
    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_uniqueness_of(:token) }
  end

  describe "#renew?" do
    before do
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: decoded_id_token))
    end

    context "when the decoded_id_token is nil" do
      subject(:session) { build(:session) }

      let(:decoded_id_token) { nil }

      it { is_expected.to be_renew }
    end

    context "when the decoded_id_token is present" do
      subject(:session) { build(:session, expires_at: 1.hour.from_now) }

      let(:decoded_id_token) { { "sub" => "12345", "exp" => 1.day.from_now.to_i } }

      it { is_expected.not_to be_renew }
    end
  end
end
