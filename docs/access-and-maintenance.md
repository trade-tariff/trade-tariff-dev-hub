# Access and maintenance

This guide is for maintainers. Local setup is in [README.md](../README.md).
Check [application configuration](../app/lib/trade_tariff_dev_hub.rb) before
changing access flags. `RAILS_ENV` and `ENVIRONMENT` have different purposes:
a deployed development or staging slot can run Rails in production mode.
`TradeTariffDevHub.environment` defaults to `production` when `ENVIRONMENT`
is unset.

## Organisation creation and role requests

`FEATURE_FLAG_SELF_SERVICE_ORG_CREATION` controls whether sign-in without an
invitation can create a personal organisation. If set, only `true` enables it.
If unset, it is enabled in Rails development or when `ENVIRONMENT` is
`development` or `staging`. It otherwise defaults to disabled.

`allow_passwordless_self_service_org_creation?` uses this flag directly. There
is no additional unconditional production block on organisation creation.
Production session access has a separate organisation-role check in
[AuthenticatedController](../app/controllers/authenticated_controller.rb).
Do not treat the sign-up flag as a complete description of access permissions.

`FEATURE_FLAG_ROLE_REQUEST` also accepts `true` or `false`. When unset, role
requests are enabled in Rails development and test, not by `ENVIRONMENT` alone.
Enable it explicitly when a deployed slot needs the role-request journey.

## Active key limits

The per-organisation limit is 3 active keys for each key type, enforced only
when `ENVIRONMENT=production` or `ENVIRONMENT` is unset. Admin organisations
are exempt. Revoked keys do not count. Categorisation keys are Trade Tariff
keys and count towards that limit. See [key limit validation](../app/models/concerns/key_limit_validation.rb).

## Provision Categorisation credentials

Follow the [key setup and provisioning guide](TRADE_TARIFF_KEYS_SETUP.md#categorisation-account-provisioning).
It covers prerequisites, the required container user, confirmation checks,
secure delivery and failure recovery. Provisioning changes real accounts and
credentials; it is not part of local application setup.

## Remove Playwright test keys

`bundle exec rails cleanup:api_keys` deletes `ApiKey` records whose descriptions
start with `playwright-`, and deletes their external API Gateway keys. It acts
across all organisations. It does not clean up `TradeTariffKey` records.

The [task](../lib/tasks/cleanup.rake) requires both `ENVIRONMENT=development`
and `CLEANUP_PLAYWRIGHT_KEYS_ENABLED=true`. The flag must be the literal `true`.
Otherwise it exits with an error before querying or deleting keys. Production,
staging and an unset environment are blocked, even when the flag is enabled.
`RAILS_ENV=development` alone does not enable cleanup.

Before an approved run, verify the target database and AWS account and review
the matching keys. After those checks, enable cleanup for that invocation:

```sh
ENVIRONMENT=development CLEANUP_PLAYWRIGHT_KEYS_ENABLED=true bundle exec rails cleanup:api_keys
```

These settings do not redirect the database or AWS clients. Confirm their targets
independently; do not relabel a production connection as development.

Any deployed schedule belongs to platform infrastructure, not this repository's
local setup. Check the current platform configuration before changing it.
