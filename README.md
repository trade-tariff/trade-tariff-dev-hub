# trade-tariff-dev-hub

Ruby app giving FPO operators the ability to manage their own API credentials.

## Swagger / OpenAPI docs

Generate the OpenAPI spec from request specs:

```bash
bundle exec rspec spec/integration --format documentation
bundle exec rails rswag:specs:swaggerize
```

Then start the app and view Swagger UI at `/api-docs`.

### Publish OpenAPI docs to another repository

This repo includes a GitHub Actions workflow at `.github/workflows/publish-api-docs.yml`.
It generates `swagger/v1/openapi.json` and copies it into a separate GitHub repository.

The workflow runs on:

- push to `main`
- manual run (`workflow_dispatch`)

Configure these GitHub Actions secrets in this repository:

- `API_DOCS_REPO`: target repository in `owner/repo` format
- `API_DOCS_TOKEN`: token with write access to the target repository
- `API_DOCS_TARGET_PATH`: destination file path in target repository (for example `openapi/dev-hub/openapi.json`)
- `API_DOCS_TARGET_BRANCH`: target branch (optional, defaults to `main`)

You can run it manually from the GitHub Actions tab by selecting **Publish API docs** and clicking **Run workflow**.

### Define Swagger manually in Ruby DSL (`swagger-blocks`)

If you want to describe an endpoint manually (instead of generating from request specs), you can use `swagger-blocks` style DSL:

```ruby
class HealthcheckSwagger
  include Swagger::Blocks

  swagger_root do
    key :openapi, "3.0.1"
    info do
      key :title, "Trade Tariff Dev Hub API"
      key :version, "v1"
    end
    key :paths, {}
  end

  swagger_path "/healthcheck" do
    operation :get do
      key :summary, "Returns application revision"
      key :operationId, "getHealthcheck"
      key :produces, ["application/json"]

      response 200 do
        key :description, "healthcheck response"
        schema do
          key :type, :object
          property :git_sha1 do
            key :type, :string
          end
          key :required, ["git_sha1"]
        end
      end
    end
  end
end

openapi_hash = Swagger::Blocks.build_root_json([HealthcheckSwagger])
File.write(Rails.root.join("swagger/v1/openapi.json"), JSON.pretty_generate(openapi_hash))
```

In this project we currently use `rswag` (`spec/integration/*`) as the source of truth, but this is useful when you want fully hand-written contract definitions.

## Getting started

### Localstack

We use localstack to simulate the aws services we use to enable the dev hub
to run locally.

You'll need docker and docker-compose installed with your package manager.

To bring up localstack run the following command:

```bash
docker-compose up
```

> [!TIP]
> If you're on a linux machine you'll want to alias the `host.docker.internal` namespace
>
> ```hosts
> 127.0.0.1 host.docker.internal
> ```

### Dev Bypass Authentication

For local development, you can bypass the identity service authentication by setting `DEV_BYPASS_AUTH=true` in your `.env.development` file. This allows you to log in with simple passwords instead of using the full identity service flow.

When enabled, navigate to `/dev/login` and use:

- **Admin password** (from `DEV_BYPASS_ADMIN_PASSWORD`, default: "admin") - grants admin access
- **User password** (from `DEV_BYPASS_USER_PASSWORD`, default: "dev") - grants regular user access with `trade_tariff:full` and `fpo:full` roles

The dev bypass creates test users and organisations automatically on first login. This feature is only available when `DEV_BYPASS_AUTH=true` and should never be enabled in production.

### Passwordless signup and role request flags

`ENVIRONMENT` (e.g. `production`, `staging`, `development`) is set per deploy; tests default it to `test`.

**Self-service org at sign-in (no invitation)** is gated in two steps:

1. `self_service_org_creation_enabled?` — if `FEATURE_FLAG_SELF_SERVICE_ORG_CREATION` is set, that value wins. If unset: enabled when `Rails.env.development?` or when `ENVIRONMENT` is `development` or `staging`; disabled when `ENVIRONMENT` is `production` (or anything else like `test`).
2. `allow_passwordless_self_service_org_creation?` — additionally requires `ENVIRONMENT != "production"`. So the live production slot never creates a personal org from the callback, even if the feature flag is `true`.

**Role requests** use `FEATURE_FLAG_ROLE_REQUEST`:

- If the variable is set: `true` / `false` applies in every environment.
- If unset: enabled in `development` and `test` only; disabled in deployed environments unless you set the flag (e.g. `FEATURE_FLAG_ROLE_REQUEST=true` on staging so new orgs can request `fpo:full` / `trade_tariff:full`).

**API keys and Trade Tariff keys:** the per-organisation cap (3 active keys) applies only when `ENVIRONMENT=production`. Staging, development, and local/test do not enforce that limit.

### Trade Tariff keys (identity + API Gateway)

To **create real Trade Tariff keys** (Cognito + API Gateway), set `IDENTITY_API_KEY` and `TRADE_TARIFF_USAGE_PLAN_ID` (see [docs/TRADE_TARIFF_KEYS_SETUP.md](docs/TRADE_TARIFF_KEYS_SETUP.md) for how to find the usage plan in AWS and per-environment setup).

### Playwright API key cleanup (development and staging)

API keys created by Playwright tests use a description prefix `playwright-` (e.g. `playwright-${Date.now()}`). A daily scheduled task removes these keys so the admin org doesn’t accumulate them.

- **Rake task:** `rails cleanup:api_keys` — only runs in development, or when `CLEANUP_PLAYWRIGHT_KEYS_ENABLED=true`, and cleans up Playwright keys from all organisations.
- **AWS:** In the development and staging environments, Terraform defines an ECS job (`dev-hub-job`) and an EventBridge rule that runs it daily at 03:00 UTC with command `bundle exec rails cleanup:api_keys`. Set `CLEANUP_PLAYWRIGHT_KEYS_ENABLED=true` in the `dev-hub-job-configuration` secret so the task runs the cleanup.
