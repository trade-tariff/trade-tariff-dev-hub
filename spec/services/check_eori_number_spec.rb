RSpec.describe CheckEoriNumber do
  describe "#call" do
    subject { described_class.new(client).call("GB1234567890") }

    let(:client) { instance_double(Faraday::Connection, post: response) }
    let(:response) { instance_double(Faraday::Response, status: status) }

    before { allow(Faraday).to receive(:new).and_return(client) }

    context "when the client returns a 200 status" do
      let(:status) { 200 }

      it { is_expected.to be true }
    end

    context "when the client returns a non-200 status" do
      let(:status) { 400 }

      it { is_expected.to be false }
    end
  end
end
