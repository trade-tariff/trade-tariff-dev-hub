source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails"

gem "aws-sdk-apigateway"
gem "faraday"
gem "importmap-rails"
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
  gem "annotate"
  gem "brakeman", require: false
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "pry-rails"
  gem "rspec-rails"
  gem "shoulda-matchers"
  gem "webmock"
end

group :development do
  gem "amazing_print"
  gem "rubocop-govuk", require: false
  gem "ruby-lsp-rails"
end

group :test do
  gem "rails-controller-testing"
end

group :production do
  gem "lograge"
  gem "logstash-event"
end
