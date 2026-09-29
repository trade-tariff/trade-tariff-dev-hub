# Access and maintenance

This guide is for maintainers. Local setup is in [README.md](../README.md).
Check [application configuration](../app/lib/trade_tariff_dev_hub.rb) before
changing access flags. `RAILS_ENV` and `ENVIRONMENT` have different purposes:
a deployed development or staging slot can run Rails in production mode.

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
when `ENVIRONMENT=production`. Admin organisations are exempt. Revoked keys do
not count. Categorisation keys are Trade Tariff keys and count towards that
limit. See [key limit validation](../app/models/concerns/key_limit_validation.rb).

## Provision Categorisation credentials

Follow the [key setup and provisioning guide](TRADE_TARIFF_KEYS_SETUP.md#categorisation-account-provisioning).
It covers prerequisites, the required container user, confirmation checks,
secure delivery and failure recovery. Provisioning changes real accounts and
credentials; it is not part of local application setup.

## Remove Playwright test keys

`bundle exec rails cleanup:api_keys` deletes `ApiKey` records whose descriptions
start with `playwright-`, and deletes their external API Gateway keys. It acts
across all organisations. It does not clean up `TradeTariffKey` records.

Despite the task's description, the
[implementation](../lib/tasks/cleanup.rake) has no environment guard and does not
check `CLEANUP_PLAYWRIGHT_KEYS_ENABLED`. Do not rely on that variable to make it
safe. Before running the task, verify the target database and AWS account and
review the matching keys. Use it only with approval for the target environment.

Any deployed schedule belongs to platform infrastructure, not this repository's
local setup. Check the current platform configuration before changing it.
