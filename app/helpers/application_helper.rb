module ApplicationHelper
  include Pagy::Frontend

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

  def sort_link_for(label, column, current_column: nil, current_direction: nil)
    # Determine new direction - toggle if same column, otherwise default to asc
    new_direction = if current_column == column && current_direction == "asc"
                      "desc"
                    else
                      "asc"
                    end

    # Build URL with sort parameters, preserving page parameter
    url_params = request.query_parameters.merge(
      sort: column,
      direction: new_direction,
    )
    # Remove page when changing sort to start from first page
    url_params.delete(:page) if current_column != column

    url = "#{request.path}?#{url_params.to_query}"

    # Determine if this is the current sort column to show indicator
    is_current_sort = current_column == column
    sort_indicator = if is_current_sort
                       current_direction == "asc" ? " ↑" : " ↓"
                     else
                       ""
                     end

    govuk_link_to "#{label}#{sort_indicator}", url
  end

  def status_tag(text, status: :default)
    classes = ["govuk-tag", status_tag_class(status)].compact.join(" ")
    content_tag(:strong, text, class: classes)
  end

private

  def status_tag_class(status)
    {
      active: "govuk-tag--green",
      revoked: "govuk-tag--grey",
    }[status.to_sym]
  end
end
