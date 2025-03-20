source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails"

gem "aws-sdk-apigateway"
gem "aws-sdk-dynamodb"
gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "importmap-rails"
gem "ostruct"
gem "paper_trail"
gem "pg"
gem "propshaft"
gem "puma", ">= 5.0"

gem "bootsnap", require: false

group :development, :test do
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
  gem "ruby-lsp-rspec"
end

group :test do
  gem "rails-controller-testing"
end
