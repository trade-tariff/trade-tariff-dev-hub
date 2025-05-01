module TradeTariffDevHub
  class << self
    def deletion_enabled?
      ENV.fetch("DELETION_ENABLED", "false") == "true"
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

    def eori_lookup_url
      ENV.fetch("EORI_LOOKUP_URL", "https://test-api.service.hmrc.gov.uk/customs/eori/lookup/check-multiple-eori")
    end
  end
end
