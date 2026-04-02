# frozen_string_literal: true

RSpec.shared_context "with restored ENVIRONMENT" do
  around do |example|
    original_environment = ENV["ENVIRONMENT"]
    example.run
  ensure
    ENV["ENVIRONMENT"] = original_environment
  end
end

RSpec.shared_context "with restored ENVIRONMENT and self-service org creation flag" do
  around do |example|
    original_environment = ENV["ENVIRONMENT"]
    original_flag = ENV["FEATURE_FLAG_SELF_SERVICE_ORG_CREATION"]
    example.run
  ensure
    ENV["ENVIRONMENT"] = original_environment
    if original_flag.nil?
      ENV.delete("FEATURE_FLAG_SELF_SERVICE_ORG_CREATION")
    else
      ENV["FEATURE_FLAG_SELF_SERVICE_ORG_CREATION"] = original_flag
    end
  end
end
