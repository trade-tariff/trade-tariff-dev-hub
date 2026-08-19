# Trade Tariff keys: setup and usage reporting

Trade Tariff keys are the credentials FPO operators use to call the
authenticated Trade Tariff API (as opposed to internal Dev Hub API keys,
which are a separate concept). Provisioning them touches two AWS services:
Cognito (via the identity service) for the client credentials, and API
Gateway for the key + usage plan association.

## How keys are provisioned

- `TradeTariff::CreateTradeTariffKey` (`app/services/trade_tariff/create_trade_tariff_key.rb`)
  creates a Cognito client via the identity service, then creates a matching
  API Gateway API key (`create_api_key`) and associates it with the shared
  usage plan (`create_usage_plan_key`). If either AWS call fails, it rolls
  back the Cognito client and any partially-created API key.
- `TradeTariff::RevokeTradeTariffKey` disables a key in place
  (`update_api_key`); `TradeTariff::DeleteTradeTariffKey` removes it
  (`delete_api_key`).
- Every organisation is capped at 3 active Trade Tariff keys, but only when
  `ENVIRONMENT=production` — see `README.md` for the other environment
  flags.

## Required environment variables

- `IDENTITY_API_KEY` — bearer token for the identity service's client
  credentials API.
- `TRADE_TARIFF_USAGE_PLAN_ID` — the API Gateway usage plan every Trade
  Tariff key gets associated with (`TradeTariffDevHub.trade_tariff_usage_plan_id`
  in `app/lib/trade_tariff_dev_hub.rb`). This is a pre-created Terraform
  resource (`aws_api_gateway_usage_plan.default` in
  `trade-tariff-platform-aws-terraform/environments/<env>/common/gateway.tf`)
  — find the ID in the AWS console (API Gateway → Usage Plans →
  `standard-<environment>`) or via:

  ```bash
  aws apigateway get-usage-plans --query "items[?name=='standard-<environment>'].id" --output text
  ```

## Categorisation account provisioning

Categorisation keys use the same `TRADE_TARIFF_USAGE_PLAN_ID` as other Trade
Tariff keys. In addition to the common prerequisites:

- confirm that Cognito exposes the `tariff/categorisation` OAuth scope; and
- deploy the matching authoriser and API Gateway protection before issuing credentials.

To provision an account with a key, first get a shell on AWS through cloudshell or your cli.

Then switch to the `tariff` user. By default, shells run as root, and running this task as root will change the ownership of the `/tmp/backend.crt` certificate to root. This borks things for the application which uses the `tariff` user. When the application next comes to provision a key and overwrite the certificate it will run into the following error:

```text
Failed to create Trade Tariff key: Permission denied @ rb_sysopen - /tmp/backend.crt
```

You can switch to the tariff user with:

```sh
su -s /bin/sh tariff
id
```

Ensure `id` comes back as `tariff`. Only then can you run the task in the target dev hub container:

```sh
bin/rails 'categorisation_accounts:create[person@example.com,Example Traders Ltd]'
```

Use the existing `backend-green-lanes-api-keys` secret's `client_contact` as the email and `name` as the organisation name. Do not pass the secret's credentials to this task. The prompt displays the environment, email, and organisation name. Continue only when all three are correct. The task normalises the stored email and organisation name, creates the user and organisation, grants Trade Tariff access, and creates one active categorisation credential.

On success, securely deliver these console values to the intended recipient:

- email;
- organisation name;
- client ID; and
- client secret.

The client secret is shown once and is not stored by Dev Hub. Do not put it in Slack, Jira, pull requests, shell history, or ordinary logs. Use the team's approved secure secret-sharing mechanism.

The recipient can sign in through the passwordless Identity flow using the provisioned email address.

### Failures and retries

Do not assume provisioning succeeded unless the task prints all four output values. Local account creation is transactional, and key creation attempts to remove any Cognito or API Gateway resources it created after a later failure.

If cleanup itself reports an error, inspect Dev Hub, Identity, and API Gateway before retrying so that an orphaned external credential is not overlooked. The task rejects an email that already belongs to a Dev Hub account.

## Measuring active Trade Tariff key usage

As of HMRC-2632, **production** has API Gateway access logging and detailed
CloudWatch metrics enabled (see the `api-gateway` Terraform module's
`access_logging_enabled` flag). Development and staging only have detailed
metrics enabled — access logging is a production-only cost trade-off, so
there is no per-key request log to query in those environments.

To answer "has this key been used, and how often?" in production:

- **Per-key request counts (no logs, fastest):**

  ```bash
  aws apigateway get-usage \
    --usage-plan-id <TRADE_TARIFF_USAGE_PLAN_ID> \
    --start-date 2026-07-12 --end-date 2026-08-11
  ```

  Returns daily request counts per API key ID for the date range (max ~90
  days). Cross-reference the returned key IDs against `TradeTariffKey.api_gateway_id`
  to map back to an organisation.

- **Per-request detail (source IP, path, status):** run the saved CloudWatch
  Logs Insights query `api-production/active-api-keys` against the log group
  `/aws/apigateway/api-production/access-logs`, with a 30- or 90-day time
  range. It aggregates request counts by `apiKeyId`.

- **Aggregate trends (request volume, error rates):** once `AWS/ApiGateway`
  metrics are flowing through the existing New Relic CloudWatch metric
  stream, build a dashboard there for overall request/error/latency trends
  (this does not break down by individual API key — use `get-usage` or Logs
  Insights for that).

## Limitations

- Historical usage from before HMRC-2632 cannot be reconstructed — access
  logging was not enabled prior to this change.
- Development and staging have no access logging, so per-key usage in those
  environments can only be checked via `aws apigateway get-usage` (works
  everywhere a usage plan exists), not via log queries.
