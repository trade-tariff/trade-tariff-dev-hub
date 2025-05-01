RSpec.shared_context "with stubbed emails" do
  let(:notifier_service) { GovukNotifier.new(client) }
  let(:client) { instance_double(Notifications::Client) }

  before do
    allow(GovukNotifier).to receive(:new).and_return notifier_service
    allow(notifier_service).to receive(:call)
  end
end
