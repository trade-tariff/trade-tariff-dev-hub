module ApplicationHelper
  def feedback_link
    govuk_link_to "What did you think of this service?", feedback_url, target: "_blank"
  end

  def documentation_link
    govuk_link_to "API documentation (opens in new tab)", documentation_url, target: "_blank"
  end

  def documentation_url
    ENV.fetch(
      "DOCUMENTATION_URL",
      "https://api.trade-tariff.service.gov.uk/fpo.html",
    )
  end

  def feedback_url
    ENV.fetch(
      "FEEDBACK_URL",
      "http://localhost:3001/feedback",
    )
  end

  def terms_and_conditions_url
    ENV.fetch(
      "TERMS_AND_CONDITIONS_URL",
      "https://api.trade-tariff.service.gov.uk/fpo/terms-and-conditions.html",
    )
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

  def terms_link
    govuk_link_to "terms and conditions of the Commodity Code Identification Tool (opens in new tab)", terms_and_conditions_url, target: "_blank", rel: "noopener noreferrer"
  end
end
