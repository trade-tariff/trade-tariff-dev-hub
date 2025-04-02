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
