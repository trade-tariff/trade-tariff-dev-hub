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

  def carrier_scheme_link
    govuk_link_to "apply for the UK Carrier scheme here (opens in new tab)",
                  "https://www.gov.uk/guidance/apply-for-the-uk-carrier-scheme",
                  target: "_blank",
                  rel: "noopener noreferrer"
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

  def user_verification_steps_review_answers_terms_hint
    t("helpers.hint.user_verification_steps_review_answers.terms_html", terms_link: terms_link)
  end

  def carrier_scheme_inset_text
    govuk_inset_text text: "To use this service, your organisation must be UK Carrier Scheme (UKC) registered. You can #{carrier_scheme_link}".html_safe
  end
end
