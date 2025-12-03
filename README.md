# trade-tariff-dev-hub

Ruby app giving FPO operators the ability to manage their own API credentials.

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
