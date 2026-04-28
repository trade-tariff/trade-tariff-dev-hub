class PagesController < ApplicationController
  def cookies_info
    render :cookies
  end

  def privacy; end

  def cookies_policy
    @current_usage_choice = current_usage_choice
  end

  def update_cookies_policy
    usage_param = params[:usage].to_s
    unless %w[true false].include?(usage_param)
      redirect_to cookies_policy_path, alert: "Select whether to allow cookies that measure website use"
      return
    end
    usage = usage_param == "true"

    # httponly: false is required so the JS cookie banner in app/javascript/application.js
    # can read the consent choice to decide which banner state to show. The same cookie is
    # written from JS; without this, the server-side write would be readable only on the
    # next request, not immediately after redirect.
    cookies[TradeTariffDevHub::POLICY_COOKIE_NAME] = {
      value: { usage: usage, remember_settings: usage }.to_json,
      expires: 1.year.from_now,
      path: "/",
      same_site: :lax,
      httponly: false,
      secure: TradeTariffDevHub.deployed_environment?,
    }

    delete_analytics_cookies unless usage

    redirect_to cookies_policy_path, notice: "Your cookie settings have been saved"
  end

private

  def current_usage_choice
    consent = AnalyticsConsent.from_cookie(cookies[TradeTariffDevHub::POLICY_COOKIE_NAME])
    consent.usage_choice
  end

  def delete_analytics_cookies
    request.cookies.each_key do |name|
      next unless TradeTariffDevHub::ANALYTICS_COOKIE_PREFIXES.any? { |prefix| name.start_with?(prefix) }

      cookies.delete(name, path: "/")
      TradeTariffDevHub.analytics_cookie_delete_domains(request.host).each do |domain|
        cookies.delete(name, path: "/", domain: domain)
      end
    end
  end
end
