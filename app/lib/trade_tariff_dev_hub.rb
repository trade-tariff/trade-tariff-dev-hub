module TradeTariffDevHub
  class << self
    def deletion_enabled?
      ENV.fetch("DELETION_ENABLED", "false") == "true"
    end
  end
end
