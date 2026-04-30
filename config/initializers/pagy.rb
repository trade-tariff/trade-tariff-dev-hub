# Pagy 9+ uses :limit for page size (not :items). See https://ddnexus.github.io/pagy/docs/api/pagy/
Pagy::DEFAULT[:limit] = TradeTariffDevHub::ADMIN_PAGY_PAGE_SIZE

# Integer: number of page links in the sliding window (not a legacy array).
Pagy::DEFAULT[:size] = 7

# In development, code reload can run before initializers; keep DEFAULT aligned on each boot/reload.
Rails.application.config.to_prepare do
  Pagy::DEFAULT[:limit] = TradeTariffDevHub::ADMIN_PAGY_PAGE_SIZE
  Pagy::DEFAULT[:size] = 7
end
