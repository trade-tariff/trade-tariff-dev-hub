module ApplicationHelper
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
end
