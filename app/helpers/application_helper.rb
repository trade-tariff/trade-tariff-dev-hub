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

  def created_on(record)
    return "" if record.created_at.blank?
    return "Today" if record.created_at.today?

    record.created_at.to_date.to_formatted_s(:govuk_short)
  end

  def navigation_item_for(header, text, path)
    active = current_page?(path)

    header.with_navigation_item(text: text, href: path, active: active)
  end
end
