module ApplicationHelper
  def documentation_link
    govuk_link_to "API documentation (opens in new tab)", TradeTariffDevHub.documentation_url, target: "_blank"
  end

  def feedback_link
    govuk_link_to "What did you think of this service?", TradeTariffDevHub.feedback_url, target: "_blank"
  end

  def terms_link
    govuk_link_to "terms and conditions of the Commodity Code Identification Tool (opens in new tab)", TradeTariffDevHub.terms_and_conditions_url, target: "_blank", rel: "noopener noreferrer"
  end

  def fpo_usage_terms
    option = Struct.new(:id, :text)
    range = (1..4)
    range.map do |index|
      option.new(
        index,
        t("fpo_usage_terms.term#{index}"),
      )
    end
  end

  def fpo_usage_terms_hint
    t("fpo_usage_terms.terms_hint_html", terms_link: terms_link)
  end
end
