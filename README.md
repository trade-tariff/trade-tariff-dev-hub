# Trade Tariff Dev Hub

Trade Tariff Dev Hub is the developer portal for Fast Parcel Operators (FPOs)
and other organisations that use protected Trade Tariff APIs. Users sign in,
manage organisation membership, request access and create or revoke API credentials.

This Ruby on Rails application stores users, organisations and key metadata in
PostgreSQL. It uses [Identity](https://github.com/trade-tariff/identity) for
passwordless sign-in and client credentials, and AWS API Gateway for API keys.
It is not the public tariff website or the API documentation site.

Related projects:

- [Trade Tariff Backend](https://github.com/trade-tariff/trade-tariff-backend): tariff APIs and FPO integration.
- [Trade Tariff API documentation](https://docs.trade-tariff.service.gov.uk/): guidance for API consumers.
- [Dev Hub end-to-end tests](https://github.com/trade-tariff/trade-tariff-fpo-dev-hub-e2e): browser tests for deployed journeys.

## Run locally

### Prerequisites

- Ruby at the version in [.ruby-version](.ruby-version) and Bundler.
- PostgreSQL, with a local user that can create development and test databases.
- A configured Identity service for sign-in journeys.
- Docker Compose if you need LocalStack for local AWS integration work.

Clone this repository, or follow the [fork workflow](CONTRIBUTING.md#fork-and-branch)
if you want to contribute without write access.

### Configure the application

Put local overrides in `.env.development.local`. The tracked
[.env.development](.env.development) contains defaults, not a complete working
Identity or AWS environment. Do not use production credentials for local work.

In Rails development mode, `BYPASS_AUTHENTICATION=true` (set in
`.env.development`) signs you in as the dummy account (`dummy@user.com`,
**Dummy Dev Org**) when you click **Start now**, without Identity. Set
`BYPASS_AUTHENTICATION=false` in `.env.development.local` to sign in through
Identity instead. When the variable is unset, sign-in uses Identity. It has no
effect in other Rails environments.

[config/database.yml](config/database.yml) reads `PGHOST` and `DB_USER`, which
default to `localhost` and `postgres`. The databases are
`tariff_dev_hub_development` and `tariff_dev_hub_test`.

Passwordless sign-in requires `IDENTITY_BASE_URL`, `IDENTITY_CONSUMER`,
`IDENTITY_COGNITO_JWKS_URL` and `IDENTITY_ENCRYPTION_SECRET`, matched to the
Identity service. The consumer defaults to `portal`. Without that integration,
you can work on code and run mocked tests, but cannot complete a real sign-in.

Creating Trade Tariff credentials also needs `IDENTITY_API_KEY` and
`TRADE_TARIFF_USAGE_PLAN_ID`. See the
[key setup guide](docs/TRADE_TARIFF_KEYS_SETUP.md) before testing key creation.
It changes external resources and can issue usable credentials.

### Set up and start

```sh
bin/setup --skip-server
bin/dev
```

`bin/setup` installs Ruby dependencies and prepares the database. Without
`--skip-server`, it also starts the application. Open <http://localhost:3004>.

For local AWS integration work, the Compose file starts LocalStack only:

```sh
docker compose up -d localstack
```

It does not start PostgreSQL or Identity, or create a usage plan. AWS clients
use the AWS SDK configuration; starting LocalStack alone does not redirect
requests to it. Configure and verify a local endpoint and disposable resources
before testing key creation or deletion. Do not assume `LOCALSTACK_HOST` alone
changes the SDK endpoint.

## Run checks

With PostgreSQL available:

```sh
bundle install
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
bundle exec rubocop
bundle exec brakeman
```

The RSpec suite mocks external requests. It does not need live AWS or Identity
credentials. See [CONTRIBUTING.md](CONTRIBUTING.md) for hooks and pull requests.
[GitHub Actions](.github/workflows/ci.yml) defines the CI checks.

## Find your way around

- [Routes](config/routes.rb): sign-in, organisations, invitations and keys.
- [Services](app/services/): credential provisioning and external integrations.
- [Application configuration](app/lib/trade_tariff_dev_hub.rb): integration settings and flags.
- [Access and maintenance](docs/access-and-maintenance.md): sign-up flags, key limits and test-key cleanup.
- [Key setup and provisioning](docs/TRADE_TARIFF_KEYS_SETUP.md): maintainer-only integration tasks and secret handling.

## Contribute

Read [CONTRIBUTING.md](CONTRIBUTING.md) for reporting bugs, making a fork,
submitting changes and reporting security issues privately.

## Licence

The code and associated documentation are available under the
[MIT licence](LICENCE.md), with Crown copyright (HM Revenue & Customs).
Keep the licence and copyright notice when you reuse the software.
Third-party dependencies and assets retain their own licences.
