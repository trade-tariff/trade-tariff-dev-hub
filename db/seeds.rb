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
    name: 'ott:full',
    description: 'Full access to Online Trade Tariff public API keys',
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
  organisation.assign_role!("ott:full")

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

  # Create OTT keys for testing
  OttKey.find_or_create_by!(
    organisation_id: organisation.id,
    description: "development OTT key",
    client_id: "OTTDEVELOPMENT000001",
    secret: "dev-ott-secret-key-1234567890abcdef",
    scopes: %w[read write],
  )
  OttKey.find_or_create_by!(
    organisation_id: organisation.id,
    description: "staging OTT key",
    client_id: "OTTSTAGING00000001",
    secret: "staging-ott-secret-key-1234567890abcdef",
    scopes: %w[read],
  )
  OttKey.find_or_create_by!(
    organisation_id: organisation.id,
    description: "production OTT key",
    client_id: "OTTPRODUCTION00000001",
    secret: "prod-ott-secret-key-1234567890abcdef",
    scopes: %w[read write],
  )

  # Create admin organisation for Transform UK
  admin_organisation = Organisation.find_or_create_by!(organisation_name: "Transform UK") do |org|
    org.description = "Admin organisation for Transform UK team"
  end

  # Assign admin role to the organisation
  admin_organisation.assign_role!("admin")

  # Create admin user for development
  admin_user = User.find_or_create_by!(email_address: "dev@transformuk.com") do |user|
    user.organisation = admin_organisation
    user.user_id = "dev-admin-user"
    user.save!
  end

  # Make sure the admin user is associated with the admin organisation
  unless admin_user.organisation == admin_organisation
    admin_user.update!(organisation: admin_organisation)
  end

  # Create some test invitations for the admin organisation
  Invitation.find_or_create_by!(
    invitee_email: "test-admin@transformuk.com",
    organisation: admin_organisation,
    user: admin_user,
    status: "pending"
  )

  Invitation.find_or_create_by!(
    invitee_email: "revoked-admin@transformuk.com",
    organisation: admin_organisation,
    user: admin_user,
    status: "revoked"
  )

  # Create dummy organisations for admin testing
  # Organisation 1: OTT Only
  ott_only_org = Organisation.find_or_create_by!(organisation_name: "Acme Logistics Ltd") do |org|
    org.description = "Transport and logistics company"
  end
  ott_only_org.assign_role!("ott:full")

  # Create 3 users for OTT only org
  alice = User.find_or_create_by!(email_address: "alice.white@acmelogistics.example.com") do |u|
    u.organisation = ott_only_org
    u.user_id = "alice-white-acme"
    u.save!
  end

  User.find_or_create_by!(email_address: "bob.smith@acmelogistics.example.com") do |u|
    u.organisation = ott_only_org
    u.user_id = "bob-smith-acme"
    u.save!
  end

  User.find_or_create_by!(email_address: "carol.jones@acmelogistics.example.com") do |u|
    u.organisation = ott_only_org
    u.user_id = "carol-jones-acme"
    u.save!
  end

  # Create invitations for OTT only org
  Invitation.find_or_create_by!(
    invitee_email: "john.doe@acmelogistics.example.com",
    organisation: ott_only_org,
    user: alice,
    status: "pending"
  )

  Invitation.find_or_create_by!(
    invitee_email: "jane.smith@acmelogistics.example.com",
    organisation: ott_only_org,
    user: alice,
    status: "revoked"
  )

  # Create OTT keys for OTT only org
  OttKey.find_or_create_by!(
    organisation_id: ott_only_org.id,
    client_id: "OTTACME00000000001",
    secret: "acme-ott-secret-key-abcdefghijklmnop"
  ) do |key|
    key.scopes = %w[read write]
    key.description = "Acme Production OTT Key"
  end

  OttKey.find_or_create_by!(
    organisation_id: ott_only_org.id,
    client_id: "OTTACME00000000002",
    secret: "acme-ott-test-secret-abcdefghijklm"
  ) do |key|
    key.scopes = %w[read]
    key.description = "Acme Test OTT Key"
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

  # Organisation 3: Both OTT and FPO
  both_org = Organisation.find_or_create_by!(organisation_name: "TechFreight Solutions") do |org|
    org.description = "Integrated freight technology platform"
  end
  both_org.assign_role!("ott:full")
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

  # Create OTT keys for both org
  OttKey.find_or_create_by!(
    organisation_id: both_org.id,
    client_id: "OTTTECH00000000001",
    secret: "tech-ott-secret-key-123456789abcdef"
  ) do |key|
    key.scopes = %w[read write]
    key.description = "TechFreight Production OTT Key"
  end

  OttKey.find_or_create_by!(
    organisation_id: both_org.id,
    client_id: "OTTTECH00000000002",
    secret: "tech-ott-dev-secret-key-987654321"
  ) do |key|
    key.scopes = %w[read]
    key.description = "TechFreight Development OTT Key"
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
