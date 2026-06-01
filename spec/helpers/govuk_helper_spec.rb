RSpec.describe GovukHelper, type: :helper do
  describe "#govuk_button_group_form_to" do
    subject(:button_group) do
      helper.govuk_button_group_form_to(
        "Revoke",
        "/api_keys/123/revoke",
        method: :patch,
        cancel_path: "/api_keys",
        warning: true,
      )
    end

    let(:document) { Nokogiri::HTML.fragment(button_group) }
    let(:form) { document.at_css("form") }
    let(:group) { form.at_css(".govuk-button-group") }
    let(:button) { group.at_css("button") }
    let(:cancel_link) { group.at_css("a") }

    it "renders a form around the GOV.UK button group", :aggregate_failures do
      expect(form["action"]).to eq("/api_keys/123/revoke")
      expect(form["method"]).to eq("post")
      expect(form.at_css('input[name="_method"]')["value"]).to eq("patch")
      expect(group).to be_present
    end

    it "renders the action as a warning GOV.UK submit button", :aggregate_failures do
      expect(button.text).to include("Revoke")
      expect(button["type"]).to eq("submit")
      expect(button["class"]).to eq("govuk-button govuk-button--warning")
      expect(button["data-module"]).to eq("govuk-button")
    end

    it "renders cancel as an aligned GOV.UK link", :aggregate_failures do
      expect(cancel_link.text).to include("Cancel")
      expect(cancel_link["href"]).to eq("/api_keys")
      expect(cancel_link["class"]).to eq("govuk-link")
    end
  end
end
