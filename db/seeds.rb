# Create roles
[
  {
    name: 'admin',
    description: 'Full access to all features and settings',
  },
  {
    name: 'fpo:full',
    description: 'Full access to FPO (Fast Parcel Operator) API keys'
  },
  {
    name: 'trade_tariff:full',
    description: 'Full access to Trade Tariff public API keys',
  },
  {
    name: 'spimm:full',
    description: 'Full access to SPIMM (Simplified Process for Internal Market Movements) API keys.'
  }
].each do |role_attrs|
  Role.find_or_create_by(name: role_attrs[:name]) do |role|
    role.description = role_attrs[:description]
  end
end

ClientRateLimitTier.find_or_create_by!(
  name: "free",
  refill_rate: 10,
  refill_interval: 60,
  refill_max: 50,
)

ClientRateLimitTier.find_or_create_by!(
  name: "standard",
  refill_rate: 200,
  refill_interval: 60,
  refill_max: 500,
)

ClientRateLimitTier.find_or_create_by!(
  name: "premium",
  refill_rate: 500,
  refill_interval: 60,
  refill_max: 1000,
)

if Rails.env.development?
  # Default to localhost if LOCALSTACK_HOST is not set
  localstack_host = ENV['LOCALSTACK_HOST'] || 'localhost'
  localstack_port = ENV['LOCALSTACK_PORT'] || '4566'

  localstack_running = Timeout.timeout(1) do
    begin
      s = TCPSocket.new(localstack_host, localstack_port)
      s.close
      true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Timeout::Error, Socket::ResolutionError
      false
    end
  end

  user = User.dummy_user!
  organisation = user.organisation
  organisation.assign_role!("fpo:full")
  organisation.assign_role!("trade_tariff:full")

  Invitation.find_or_create_by!(
    invitee_email: "jeremy.bentham@philos101.com",
    organisation: organisation,
    user: user,
    status: "accepted",
  )
  Invitation.find_or_create_by!(
    invitee_email: "wilfred.salience@esquire.com",
    organisation: organisation,
    user: user,
    status: "pending",
  )
  Invitation.find_or_create_by!(
    invitee_email: "isaac.asimov@foundation.hist",
    organisation: organisation,
    user: user,
    status: "revoked",
  )

  User.find_or_create_by!(
    email_address: "jeremy.bentham@econ101.com",
    organisation: organisation,
    user_id: "jeremy-bentham",
  )

  if localstack_running
    CreateApiKey.new.call("local-development", "development API key")
    CreateApiKey.new.call("local-development", "staging API key")
    CreateApiKey.new.call("local-development", "production API key")
  else
    ApiKey.find_or_create_by!(
      organisation_id: organisation.id,
      description: "development API key",
      api_key_id: "development-api-key",
      api_gateway_id: "development-api-gateway-id",
      secret: "foo",
      usage_plan_id: "usage-plan-id",
    )
    ApiKey.find_or_create_by!(
      organisation_id: organisation.id,
      description: "staging API key",
      api_key_id: "staging-api-key",
      api_gateway_id: "staging-api-gateway-id",
      secret: "foo",
      usage_plan_id: "usage-plan-id",
    )
    ApiKey.find_or_create_by!(
      organisation_id: organisation.id,
      description: "production API key",
      api_key_id: "production-api-key",
      api_gateway_id: "production-api-gateway-id",
      secret: "foo",
      usage_plan_id: "usage-plan-id",
    )
  end

  api_key = ApiKey.find_by(description: "staging API key")

  if localstack_running
    RevokeApiKey.new.call(api_key)
  else
    api_key.enabled = false
    api_key.save!
  end

  # Create Trade Tariff keys for testing
  TradeTariffKey.find_or_create_by!(
    organisation_id: organisation.id,
    description: "development Trade Tariff key",
    client_id: "TTDEVELOPMENT0000001",
    secret: "dev-trade-tariff-secret-key-1234567890abcdef",
    scopes: %w[read write],
  )
  TradeTariffKey.find_or_create_by!(
    organisation_id: organisation.id,
    description: "staging Trade Tariff key",
    client_id: "TTSTAGING0000000001",
    secret: "staging-trade-tariff-secret-key-1234567890abcdef",
    scopes: %w[read],
  )
  TradeTariffKey.find_or_create_by!(
    organisation_id: organisation.id,
    description: "production Trade Tariff key",
    client_id: "TTPRODUCTION00000001",
    secret: "prod-trade-tariff-secret-key-1234567890abcdef",
    scopes: %w[read write],
  )

  # Create Admin Dev Org with admin role
  admin_dev_org = Organisation.find_or_create_by!(organisation_name: "Admin Dev Org") do |org|
    org.description = "Admin organisation for development testing"
  end

  # Assign admin role to the organisation
  admin_dev_org.assign_role!("admin")

  # Create 1 FPO key for Admin Dev Org
  if localstack_running
    CreateApiKey.new.call(admin_dev_org.id, "Admin Dev Org FPO Key")
  else
    ApiKey.find_or_create_by!(
      organisation_id: admin_dev_org.id,
      description: "Admin Dev Org FPO Key"
    ) do |key|
      key.api_key_id = "admin-dev-fpo-key"
      key.api_gateway_id = "admin-dev-fpo-gateway"
      key.secret = "admin-dev-fpo-secret-xyz123"
      key.usage_plan_id = "admin-dev-usage-plan"
      key.enabled = true
    end
  end

  # Create 1 Trade Tariff key for Admin Dev Org
  TradeTariff::CreateTradeTariffKey.new.call(admin_dev_org.id, "Admin Dev Org Trade Tariff Key")

  # Create regular dev user organisation (not admin)
  dev_user_org = Organisation.find_or_create_by!(organisation_name: "Dev User Org") do |org|
    org.description = "Regular user organisation for dev@transformuk.com"
  end

  # Assign only trade_tariff:full and fpo:full roles (not admin)
  dev_user_org.assign_role!("trade_tariff:full")
  dev_user_org.assign_role!("fpo:full")

  # Create dev user and associate with non-admin organisation
  dev_user = User.find_or_create_by!(email_address: "dev@transformuk.com") do |user|
    user.organisation = dev_user_org
    user.user_id = "dev-user-id"
    user.save!
  end

  # Make sure the dev user is associated with the non-admin organisation
  unless dev_user.organisation == dev_user_org
    dev_user.update!(organisation: dev_user_org)
  end

  # Create dummy organisations for admin testing
  # Organisation 1: Trade Tariff Only
  trade_tariff_only_org = Organisation.find_or_create_by!(organisation_name: "Acme Logistics Ltd") do |org|
    org.description = "Transport and logistics company"
  end
  trade_tariff_only_org.assign_role!("trade_tariff:full")

  # Create 3 users for Trade Tariff only org
  alice = User.find_or_create_by!(email_address: "alice.white@acmelogistics.example.com") do |u|
    u.organisation = trade_tariff_only_org
    u.user_id = "alice-white-acme"
    u.save!
  end

  User.find_or_create_by!(email_address: "bob.smith@acmelogistics.example.com") do |u|
    u.organisation = trade_tariff_only_org
    u.user_id = "bob-smith-acme"
    u.save!
  end

  User.find_or_create_by!(email_address: "carol.jones@acmelogistics.example.com") do |u|
    u.organisation = trade_tariff_only_org
    u.user_id = "carol-jones-acme"
    u.save!
  end

  # Create invitations for Trade Tariff only org
  Invitation.find_or_create_by!(
    invitee_email: "john.doe@acmelogistics.example.com",
    organisation: trade_tariff_only_org,
    user: alice,
    status: "pending"
  )

  Invitation.find_or_create_by!(
    invitee_email: "jane.smith@acmelogistics.example.com",
    organisation: trade_tariff_only_org,
    user: alice,
    status: "revoked"
  )

  # Create Trade Tariff keys for Trade Tariff only org
  TradeTariffKey.find_or_create_by!(
    organisation_id: trade_tariff_only_org.id,
    client_id: "TTACME000000000001",
    secret: "acme-trade-tariff-secret-key-abcdefghijklmnop"
  ) do |key|
    key.scopes = %w[read write]
    key.description = "Acme Production Trade Tariff Key"
  end

  TradeTariffKey.find_or_create_by!(
    organisation_id: trade_tariff_only_org.id,
    client_id: "TTACME000000000002",
    secret: "acme-trade-tariff-test-secret-abcdefghijklm"
  ) do |key|
    key.scopes = %w[read]
    key.description = "Acme Test Trade Tariff Key"
  end

  # Organisation 2: FPO Only
  fpo_only_org = Organisation.find_or_create_by!(organisation_name: "Global Express Services") do |org|
    org.description = "International shipping and customs"
  end
  fpo_only_org.assign_role!("fpo:full")

  # Create 3 users for FPO only org
  dave = User.find_or_create_by!(email_address: "dave.brown@globalexpress.example.com") do |u|
    u.organisation = fpo_only_org
    u.user_id = "dave-brown-global"
    u.save!
  end

  User.find_or_create_by!(email_address: "eve.wilson@globalexpress.example.com") do |u|
    u.organisation = fpo_only_org
    u.user_id = "eve-wilson-global"
    u.save!
  end

  User.find_or_create_by!(email_address: "frank.taylor@globalexpress.example.com") do |u|
    u.organisation = fpo_only_org
    u.user_id = "frank-taylor-global"
    u.save!
  end

  # Create invitations for FPO only org
  Invitation.find_or_create_by!(
    invitee_email: "sarah.jones@globalexpress.example.com",
    organisation: fpo_only_org,
    user: dave,
    status: "pending"
  )

  Invitation.find_or_create_by!(
    invitee_email: "revoked-user@globalexpress.example.com",
    organisation: fpo_only_org,
    user: dave,
    status: "revoked"
  )

  Invitation.find_or_create_by!(
    invitee_email: "lisa.chen@globalexpress.example.com",
    organisation: fpo_only_org,
    user: dave,
    status: "accepted"
  )

  # Create API keys for FPO only org
  unless localstack_running
    ApiKey.find_or_create_by!(
      organisation_id: fpo_only_org.id,
      api_key_id: "global-prod-api-key"
    ) do |key|
      key.description = "Global Express Production Key"
      key.api_gateway_id = "global-prod-gateway"
      key.secret = "global-prod-secret-xyz123"
      key.usage_plan_id = "global-usage-plan"
      key.enabled = true
    end

    ApiKey.find_or_create_by!(
      organisation_id: fpo_only_org.id,
      api_key_id: "global-staging-api-key"
    ) do |key|
      key.description = "Global Express Staging Key"
      key.api_gateway_id = "global-staging-gateway"
      key.secret = "global-staging-secret-xyz123"
      key.usage_plan_id = "global-usage-plan"
      key.enabled = true
    end
  end

  # Organisation 3: Both Trade Tariff and FPO
  both_org = Organisation.find_or_create_by!(organisation_name: "TechFreight Solutions") do |org|
    org.description = "Integrated freight technology platform"
  end
  both_org.assign_role!("trade_tariff:full")
  both_org.assign_role!("fpo:full")

  # Create 3 users for both org
  grace = User.find_or_create_by!(email_address: "grace.martin@techfreight.example.com") do |u|
    u.organisation = both_org
    u.user_id = "grace-martin-tech"
    u.save!
  end

  User.find_or_create_by!(email_address: "henry.clark@techfreight.example.com") do |u|
    u.organisation = both_org
    u.user_id = "henry-clark-tech"
    u.save!
  end

  User.find_or_create_by!(email_address: "ivy.lewis@techfreight.example.com") do |u|
    u.organisation = both_org
    u.user_id = "ivy-lewis-tech"
    u.save!
  end

  # Create invitations for both org
  Invitation.find_or_create_by!(
    invitee_email: "tom.wilson@techfreight.example.com",
    organisation: both_org,
    user: grace,
    status: "pending"
  )

  Invitation.find_or_create_by!(
    invitee_email: "emma.thompson@techfreight.example.com",
    organisation: both_org,
    user: grace,
    status: "revoked"
  )

  Invitation.find_or_create_by!(
    invitee_email: "oliver.brown@techfreight.example.com",
    organisation: both_org,
    user: grace,
    status: "pending"
  )

  # Create Trade Tariff keys for both org
  TradeTariffKey.find_or_create_by!(
    organisation_id: both_org.id,
    client_id: "TTTECH000000000001",
    secret: "tech-trade-tariff-secret-key-123456789abcdef"
  ) do |key|
    key.scopes = %w[read write]
    key.description = "TechFreight Production Trade Tariff Key"
  end

  TradeTariffKey.find_or_create_by!(
    organisation_id: both_org.id,
    client_id: "TTTECH000000000002",
    secret: "tech-trade-tariff-dev-secret-key-987654321"
  ) do |key|
    key.scopes = %w[read]
    key.description = "TechFreight Development Trade Tariff Key"
  end

  # Create API keys for both org
  unless localstack_running
    ApiKey.find_or_create_by!(
      organisation_id: both_org.id,
      api_key_id: "tech-prod-api-key"
    ) do |key|
      key.description = "TechFreight Production FPO Key"
      key.api_gateway_id = "tech-prod-gateway"
      key.secret = "tech-prod-secret-abc123"
      key.usage_plan_id = "tech-usage-plan"
      key.enabled = true
    end

    ApiKey.find_or_create_by!(
      organisation_id: both_org.id,
      api_key_id: "tech-staging-api-key"
    ) do |key|
      key.description = "TechFreight Staging FPO Key"
      key.api_gateway_id = "tech-staging-gateway"
      key.secret = "tech-staging-secret-def456"
      key.usage_plan_id = "tech-usage-plan"
      key.enabled = false
    end
  end
end
