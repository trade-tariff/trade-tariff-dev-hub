RSpec.describe User, type: :model do
  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  describe ".admin_emails" do
    subject(:admin_emails) { described_class.admin_emails }

    context "when an admin organisation exists" do
      let(:admin_org) { create(:organisation).tap { |org| org.assign_role!("admin") } }
      let(:other_org) { create(:organisation) }

      before do
        create(:user, organisation: admin_org, email_address: "foo@bar.com")
        create(:user, organisation: admin_org, email_address: "bar@baz.com")
        create(:user, organisation: other_org, email_address: "baz@qux.com")
      end

      it "returns the email addresses of all users in admin organisations" do
        expect(admin_emails).to contain_exactly("foo@bar.com", "bar@baz.com")
      end
    end
  end

  describe ".from_passwordless_payload!" do
    subject(:from_passwordless_payload!) { described_class.from_passwordless_payload!(decoded_token) }

    let(:decoded_token) do
      {
        "sub" => "foo",
        "email" => "foo@example.com",
      }
    end

    context "when the user already exists" do
      let!(:user) do
        create(
          :user,
          user_id: decoded_token["sub"],
          email_address: decoded_token["email"],
        )
      end

      it { is_expected.to eq(user) }
      it { expect { from_passwordless_payload! }.not_to change(described_class, :count) }
      it { expect { from_passwordless_payload! }.not_to change(Organisation, :count) }
    end

    context "when the user does not exist" do
      it { expect { from_passwordless_payload! }.to change(described_class, :count).by(1) }
      it { expect { from_passwordless_payload! }.to change(Organisation, :count).by(1) }
      it { is_expected.to have_attributes(user_id: decoded_token["sub"], email_address: decoded_token["email"]) }

      it "assigns the correct roles to the organisation" do
        user = from_passwordless_payload!

        expect(user.organisation.roles.pluck(:name)).to eq(%w[trade_tariff:full])
      end
    end

    context "when in development environment" do
      subject(:from_passwordless_payload!) { described_class.from_passwordless_payload!(decoded_token) }

      before { allow(Rails).to receive(:env).and_return("development".inquiry) }

      it { is_expected.to have_attributes(user_id: "dummy_user", email_address: "dummy@user.com") }
      it { expect { from_passwordless_payload! }.to change(described_class, :count).by(1) }
      it { expect { from_passwordless_payload! }.to change(Organisation, :count).by(1) }
    end
  end
end
