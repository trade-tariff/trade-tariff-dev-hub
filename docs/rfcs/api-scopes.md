# API Scope Mapping (Cognito Resource Server)

## Available Scopes

- `tariff/read` – read access to Tariff API
- `tariff/categorisation` – access to Categorisation (green_lanes) endpoints
- `tariff/fpo` – access to Freeports API (future integration)
- `tariff/write` – admin/internal (legacy)

## Path Mapping

### tariff/read
- /uk/api/*
- /xi/api/*
(excluding categorisation routes)

### tariff/categorisation
- /uk/api/green_lanes/*
- /xi/api/green_lanes/*

### tariff/fpo
- external today, future API Gateway migration

## Notes
- Dev-hub uses friendly names: read, categorisation, fpo.
- Identity-service maps these to OAuth scopes via SCOPE_MAP.