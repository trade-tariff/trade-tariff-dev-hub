# Add support for Flat RBAC

- RFC ID: [RFC-001]
- Title: Support Flat RBAC
- Authors: [Will Fish]
- Status: Draft
- Created: Sept 18, 2025
- Updated: Sept 18, 2025
- Version: 1.0

## Abstract

The developer portal will encapsulate management of various kinds of credentials across various services enabling access to different APIs. We need some means of verifying which roles can have access to these credentials using Role Based Access Control (RBAC). In this RFC I'm proposing that we use Flat RBAC as a Phase 1 for simplicity but enable a flexible migration path to Hierarchical RBAC in future.

## Motivation and Rationale

Our goal is to provide differential access to various kinds of user to access various kinds of credential that are capable of accessing variout UK Trade Tariff services.

For example, we have users that are strictly Fast Parcel Operators (FPOs) who do not typically need access to APIs for Simplified Process for Internal Market Movements (SPIMM) and vice versa. We also have many public APIs which we desire to be publicly accessible with rate limits with more permissive limits when managed credentials are used.

Ultimately, we want to design an RBAC architecture that gets us as close as possible to the following principles:

1. Simple - Its easy to manage and to add new roles
2. Extensible - Whatever we build can be easily changed
3. Principle of Least Privilege - We clearly demarcate access to specific services and avoid cross-service and cross-resource access for granular permissions
4. Zero Trust - We always verify whether the current organisation has access to the given resource at the correct access level

## Proposed solution

### Flexible Flat RBAC

From the perspective of simple I think it makes sense to not diverge too far from a Flat RBAC (e.g. direct assignment of users to roles) but we also want a degree of flexibility so would benefit from being able to compose sets of permissions that can be inherited from. We can achieve extensibility by building out role granularity that makes composition of permission sets later easier. And can achieve a zero trust setup by making sure that access to each of the different services is part of the granularity of the permissions.

The idea is that we have a table for `roles` that is associated to organisations via an `organisations_roles` table. At the point of asking the question about whether the current user has access to manage a given resource we will check the database for that users' roles.

```sql
           Table "public.organisations_roles"
     Column      | Type | Collation | Nullable | Default
-----------------+------+-----------+----------+---------
 organisation_id | uuid |           | not null |
 role_id         | uuid |           | not null |
```

```sql
                                  Table "public.roles"
   Column    |              Type              | Collation | Nullable |      Default
-------------+--------------------------------+-----------+----------+-------------------
 id          | uuid                           |           | not null | gen_random_uuid()
 name        | character varying              |           | not null |
 description | character varying              |           | not null |
 created_at  | timestamp(6) without time zone |           | not null |
 updated_at  | timestamp(6) without time zone |           | not null |
```

The role names themselves will need to conform to a standard structure that encourages granularity to enable zero trust and I propose that we reflect the service, resource and access levels in each role.

*Access levels* should be standardised to the following:

- `read` - Can view the resource
- `write` - Can view, create and update (and occasionally destroy) the resource

*Resources* are arbitary labels that reflect the resource being accessed - typically corresponding to some resource path in the developer portal.

*Services* are the different UK Trade Tariff services that we have - e.g. FPO, SPIMM, Public APIs etc.

#### Role format

My suggestion is that all role parts should be stored in the `name` column of the `roles` table in the following format:

```xml
<service>:<resource>:<access-level>
```

For example a role that has the ability to manage OTT API keys for the public APIs might be called:

- `ott:apikeys:full`

I propose that we also have some flat roles that do not conform to this format for superuser type access to the portal. These roles should be few and far between and only used when absolutely necessary. Examples of such roles might be:

- `admin`

### Extended Hierarchical RBAC

The above model can be extended to support Hierarchical RBAC by allowing roles to inherit from other roles and adding a step that allows the authorisation process to derive granular permissions from inherited roles.

If the permissions are granular enough we can compose sets of permissions that can be inherited from. This will make it easier to manage roles and to add new roles in future.

We can achieve this by building out a Directed Acyclic Graph (DAG) of roles using a `roles_inheritance` table.

```sql
           Table "public.roles_inheritance"
   Column    | Type | Collation | Nullable | Default
-------------+------+-----------+----------+---------
    parent_id| uuid |           | not null |
    child_id | uuid |           | not null |
```

If we go for this, I propose that we restrict inheritance to only one level deep to keep things simple/avoid circularity. This means that a role can inherit from multiple roles but those roles cannot themselves inherit from other roles. This keeps the graph flat and avoids complexity in the authorisation process.
