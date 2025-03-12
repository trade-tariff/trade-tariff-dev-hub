source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails"

gem "importmap-rails"
gem "ostruct"
gem "paper_trail"
gem "pg"
gem "propshaft"
gem "puma", ">= 5.0"
gem "stimulus-rails"
gem "turbo-rails"

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
  gem "awesome_print"
  gem "rubocop-govuk", require: false
  gem "ruby-lsp-rails"
  gem "ruby-lsp-rspec"
end
