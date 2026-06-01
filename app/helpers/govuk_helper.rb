module GovukHelper
  def govuk_form_for(*args, **options, &block)
    merged = options.dup
    merged[:builder] = GOVUKDesignSystemFormBuilder::FormBuilder
    merged[:html] ||= {}
    merged[:html][:novalidate] = true

    form_for(*args, **merged) do |form|
      safe_join [
        form.govuk_error_summary,
        capture(form, &block),
      ], "\n"
    end
  end

  def govuk_button_group_form_to(button_text, path, method:, cancel_path:, **button_options)
    form_tag(path, method:) do
      content_tag(:div, class: "govuk-button-group") do
        safe_join(
          [
            button_tag(button_text, class: govuk_button_classes(**button_options), data: { module: "govuk-button" }),
            govuk_link_to("Cancel", cancel_path),
          ],
          "\n",
        )
      end
    end
  end
end
