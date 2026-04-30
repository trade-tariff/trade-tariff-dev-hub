# frozen_string_literal: true

# GOV.UK Design System pagination markup (see https://design-system.service.gov.uk/components/pagination/)
# wired to Pagy, replacing the default pagy_nav HTML which does not match GDS styling.
module GovukPagyHelper
  def govuk_pagy_nav(pagy)
    return "".html_safe if pagy.pages <= 1

    content_tag(:nav, class: "govuk-pagination govuk-!-margin-top-6", role: "navigation", "aria-label": "Pagination") do
      safe_join(
        [
          govuk_pagy_prev(pagy),
          govuk_pagy_page_list(pagy),
          govuk_pagy_next(pagy),
        ].compact_blank,
      )
    end
  end

private

  def govuk_pagy_prev(pagy)
    return if pagy.prev.blank?

    content_tag(:div, class: "govuk-pagination__prev") do
      link_to(
        pagy_url_for(pagy, pagy.prev),
        class: "govuk-link govuk-pagination__link",
        rel: "prev",
      ) do
        tag.span(class: "govuk-pagination__link-label") do
          safe_join(["Previous ", tag.span("page", class: "govuk-visually-hidden")])
        end
      end
    end
  end

  def govuk_pagy_next(pagy)
    return if pagy.next.blank?

    content_tag(:div, class: "govuk-pagination__next") do
      link_to(
        pagy_url_for(pagy, pagy.next),
        class: "govuk-link govuk-pagination__link",
        rel: "next",
      ) do
        tag.span(class: "govuk-pagination__link-label") do
          safe_join(["Next ", tag.span("page", class: "govuk-visually-hidden")])
        end
      end
    end
  end

  def govuk_pagy_page_list(pagy)
    series = pagy.series
    return if series.empty?

    content_tag(:ul, class: "govuk-pagination__list") do
      safe_join(
        series.map { |item| govuk_pagy_series_item(pagy, item) },
      )
    end
  end

  def govuk_pagy_series_item(pagy, item)
    case item
    when :gap
      content_tag(:li, class: "govuk-pagination__item govuk-pagination__item--ellipsis", "aria-hidden": "true") do
        tag.span("⋯", class: "govuk-pagination__link-title")
      end
    when String
      label = pagy.label_for(item)
      content_tag(:li, class: "govuk-pagination__item govuk-pagination__item--current") do
        link_to(
          label,
          pagy_url_for(pagy, item.to_i),
          class: "govuk-pagination__link",
          aria: { current: "page" },
          "aria-label": "Page #{label}",
        )
      end
    else
      content_tag(:li, class: "govuk-pagination__item") do
        link_to(
          item,
          pagy_url_for(pagy, item),
          class: "govuk-link govuk-pagination__link",
          "aria-label": "Page #{item}",
        )
      end
    end
  end
end
