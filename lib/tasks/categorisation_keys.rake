# frozen_string_literal: true

namespace :categorisation_keys do
  desc "Provision a Categorisation API key for one Dev Hub organisation"
  task :provision, [:organisation_id] => :environment do |_task, args|
    organisation_id = args[:organisation_id]
    abort "Organisation ID is required" if organisation_id.blank?

    organisation = Organisation.find_by(id: organisation_id)
    abort "Organisation #{organisation_id.inspect} was not found" unless organisation

    print "Provision a Categorisation API key for #{organisation.organisation_name} (#{organisation.id})? [y/N] "
    confirmation = $stdin.gets&.strip&.downcase
    abort "Provisioning cancelled; no key was created" unless %w[y yes].include?(confirmation)

    result = TradeTariff::CreateCategorisationKey.new.call(organisation)

    puts "Categorisation API key created"
    puts "Client ID: #{result.trade_tariff_key.client_id}"
    puts "Client secret: #{result.client_secret}"
    puts "Store the client secret securely now. Dev Hub does not retain it."
  end
end
