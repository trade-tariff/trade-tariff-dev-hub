# Pull Request

## What:
<!-- A brief description of what this PR does -->

## Why:
<!-- The reasoning or context behind this change -->

## Ticket:
<!-- Link to the relevant Jira/ticket, or 'N/A' if not applicable -->

## Risk:

**Risk level:** 🟢 / 🟠 / 🔴 <!-- delete as appropriate -->

**Reason for rating:**
<!-- One or two sentences explaining your assessment, especially for Amber or Red -->

───────────────────────────────────────────────────

Rate the overall risk of deploying this change:

🟢 Green  – Low risk. Good to go, standard review applies.

🟠 Amber  – Medium risk. Socialise with the team before merging.

🔴 Red    – High risk. Requires explicit approval from Thor or Neil before merging.

───────────────────────────────────────────────────

🟢 GREEN – things that are typically low risk:
───────────────────────────────────────────────────
- New tests or improved test coverage with no production code changes
- Dependency bumps with no API changes (minor/patch gems)
- Copy or content changes to UI labels, hint text, or page titles with no logic change
- Config/env var additions that are purely additive and have safe defaults
- Refactors with full test coverage and no behaviour change
- Adding or updating CloudWatch alarms or dashboards (read-only observability)
- Terraform formatting or variable renaming with no resource recreation
- Logging improvements or additional audit trail entries (additive only)
- Feature flag changes that only affect non-production environments

🟠 AMBER – things that need a team conversation first:
───────────────────────────────────────────────────
- Changes to the operator sign-up, sign-in, or role request flows
- Modifications to how API keys or Trade Tariff keys are created, listed, or revoked
- Changes to organisation management logic (creation, membership, caps)
- New or modified calls to the identity service or AWS (Cognito, API Gateway, Secrets Manager)
- Adding or changing feature flags that affect live operator journeys
- Changes to the self-service org creation or passwordless auth behaviour
- Infrastructure changes that alter networking, security groups, or IAM permissions in non-production first
- Terraform changes that will cause a resource replacement (check plan output carefully)
- Changes to CI/CD pipeline steps or deployment order dependencies
- Removing or deprecating a route, controller action, or view still in use

🔴 RED – requires explicit approval from Thor or Neil:
───────────────────────────────────────────────────
- Changes to how Cognito user pools, app clients, or identity attributes are managed
- Modifications to API Gateway usage plans, API key scoping, or the per-org key cap in production
- Changes to authentication or session handling (JWT validation, JWKS, encryption secrets)
- Changes to admin access controls or role definitions (fpo:full, trade_tariff:full)
- Any change to production AWS infrastructure that cannot be easily rolled back
- Secrets rotation or changes to how credentials, signing keys, or API secrets are stored or accessed
- Database migrations that are destructive (dropping columns/tables, removing indexes)
- Significant architectural shifts (e.g. new identity providers, changes to the key provisioning pipeline)
