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
end
