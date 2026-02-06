# ADR-002: CRD Model for Keycloak Configuration

**Status:** Accepted  
**Date:** 2026-01-31  
**Decision Makers:** Project Team

## Context

Keycloak configuration (realms, clients, users, etc.) should be managed declaratively via Kubernetes Custom Resources. This enables GitOps workflows and integrates with the Kubernetes ecosystem.

## Decision

Implement namespace-scoped CRDs for Keycloak resources, starting with **KeycloakClient** for Milestone 1.

CRD hierarchy:
```
KeycloakInstance (cluster or namespace scoped) - via KRO
  └── KeycloakRealm (namespaced) - Milestone 2
        ├── KeycloakClient (namespaced) - Milestone 1
        ├── KeycloakUser (namespaced) - Milestone 2
        ├── KeycloakGroup (namespaced) - Milestone 2
        └── KeycloakClientScope (namespaced) - Milestone 2
```

## Rationale

- Namespace-scoped CRDs align with multi-instance isolation
- Start simple with Client CRD, expand iteratively
- Matches Kubernetes native patterns
- Enables kubectl-based management
- Works with GitOps (ArgoCD, Flux)

## Consequences

### Positive
- Declarative configuration
- Version controlled via Git
- Standard Kubernetes tooling works
- Clear resource ownership

### Negative
- Need controller/operator for reconciliation
- Schema migrations for CRD updates
- Learning curve for CRD development

## Implementation Notes

For Milestone 1 (PoC):
- KeycloakClient CRD only
- Simple controller that syncs to Keycloak Admin API
- Status subresource for sync state
- Validation via OpenAPI schema
