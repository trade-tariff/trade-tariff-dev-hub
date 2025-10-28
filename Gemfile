source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails"

gem "aws-sdk-apigateway"
gem "faraday"
gem "importmap-rails"
gem "jsonapi-serializer"
gem "jwt"
gem "paper_trail"
gem "pg"
gem "propshaft"
gem "puma"
gem "rack-cors"

# GovUK
gem "govuk-components"
gem "govuk_design_system_formbuilder"

gem "bootsnap", require: false

group :development, :test do
  gem "dotenv-rails"
  gem "pry-rails"
end

group :development do
  gem "amazing_print"
  gem "annotate"
  gem "brakeman", require: false
  gem "rubocop-govuk", require: false
  gem "ruby-lsp-rails"
end

group :test do
  gem "factory_bot_rails"
  gem "rails-controller-testing"
  gem "rspec-json_expectations"
  gem "rspec-rails"
  gem "shoulda-matchers"
  gem "webmock"
end

group :production do
  gem "lograge"
  gem "logstash-event"
end
