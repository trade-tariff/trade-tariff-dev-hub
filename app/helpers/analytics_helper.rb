module AnalyticsHelper
  def analytics_allowed?
    consent = AnalyticsConsent.from_cookie(cookies[TradeTariffDevHub::POLICY_COOKIE_NAME])
    consent.analytics_allowed?
  end
end
