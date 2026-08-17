# frozen_string_literal: true

namespace :categorisation_accounts do
  desc "Create a Dev Hub account and Categorisation API key for an email address"
  task :create, [:email_address] => :environment do |_task, args|
    email_address = args[:email_address]
    abort "Email address is required" if email_address.blank?

    puts "Create a Dev Hub account and Categorisation API key"
    puts "Environment: #{TradeTariffDevHub.environment}"
    puts "Email: #{email_address}"
    print "Continue? [y/N] "
    confirmation = $stdin.gets&.strip&.downcase
    abort "Creation cancelled; no account or key was created" unless %w[y yes].include?(confirmation)

    result = TradeTariff::CreateCategorisationAccount.new.call(email_address)

    puts "Dev Hub account and Categorisation API key created"
    puts "Email: #{result.user.email_address}"
    puts "Client ID: #{result.categorisation_key.client_id}"
    puts "Client secret: #{result.client_secret}"
    puts "Store the client secret securely now. Dev Hub does not retain it."
  end
end
