class AnalyticsConsent
  attr_reader :usage

  def self.from_cookie(raw_value)
    return new(nil) if raw_value.blank?

    parsed = JSON.parse(raw_value)
    usage = parsed.key?("usage") ? ActiveModel::Type::Boolean.new.cast(parsed["usage"]) : nil
    new(usage)
  rescue JSON::ParserError, TypeError
    new(nil)
  end

  def initialize(usage)
    @usage = usage
  end

  def usage_choice
    return nil if usage.nil?

    !!usage
  end

  def analytics_allowed?
    usage_choice == true
  end
end
