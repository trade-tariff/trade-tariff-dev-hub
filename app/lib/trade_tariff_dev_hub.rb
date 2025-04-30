module TradeTariffDevHub
  class << self
    def deletion_enabled?
      ENV.fetch("DELETION_ENABLED", "false") == "true"
    end

    def eori_lookup_url
      ENV.fetch("EORI_LOOKUP_URL", "https://test-api.service.hmrc.gov.uk/customs/eori/lookup/check-multiple-eori")
    end
  end
end
