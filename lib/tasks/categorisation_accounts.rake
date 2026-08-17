# frozen_string_literal: true

namespace :categorisation_accounts do
  desc "Create a Dev Hub account and Categorisation API key for an organisation"
  task :create, %i[email_address organisation_name] => :environment do |_task, args|
    email_address = args[:email_address]
    organisation_name = args[:organisation_name]
    abort "Email address is required" if email_address.blank?
    abort "Organisation name is required" if organisation_name.blank?

    puts "Create a Dev Hub account and Categorisation API key"
    puts "Environment: #{TradeTariffDevHub.environment}"
    puts "Email: #{email_address}"
    puts "Organisation: #{organisation_name}"
    print "Continue? [y/N] "
    confirmation = $stdin.gets&.strip&.downcase
    abort "Creation cancelled; no account or key was created" unless %w[y yes].include?(confirmation)

    result = TradeTariff::CreateCategorisationAccount.new.call(email_address, organisation_name)

    puts "Dev Hub account and Categorisation API key created"
    puts "Email: #{result.user.email_address}"
    puts "Organisation: #{result.user.organisation.organisation_name}"
    puts "Client ID: #{result.categorisation_key.client_id}"
    puts "Client secret: #{result.client_secret}"
    puts "Store the client secret securely now. Dev Hub does not retain it."
  end
end
