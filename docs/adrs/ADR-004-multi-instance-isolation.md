# ADR-004: Multi-Instance Isolation via Namespaces

**Status:** Draft  
**Date:** 2026-01-31  
**Decision Makers:** Project Team

## Context

The solution must support multiple isolated Keycloak instances per Kubernetes cluster. Each instance should be fully independent with no data or configuration leakage.

## Decision

Use **Kubernetes namespaces** as the primary isolation boundary. Each KeycloakInstance gets its own namespace containing all resources.

Pattern: `keycloak-<instance-name>`

## Rationale

- Kubernetes-native isolation mechanism
- RBAC naturally scoped to namespaces
- NetworkPolicies work at namespace level
- Resource quotas per namespace
- Clear ownership and lifecycle

## Consequences

### Positive
- Strong isolation by default
- Simple mental model
- Easy cleanup (delete namespace)
- Standard Kubernetes patterns

### Negative
- One namespace per instance (many namespaces)
- Cross-namespace communication needs explicit config
- Namespace naming conflicts possible

## Implementation

For Milestone 1:
- KRO creates namespace per instance
- All resources deployed into instance namespace
- PostgreSQL per namespace (no shared DB)
- NetworkPolicy: default deny (prepared, not enforced in PoC)

For Later:
- NetworkPolicy enforcement
- Resource quotas
- RBAC per instance

## Example

```yaml
apiVersion: kro.run/v1alpha1
kind: KeycloakInstance
metadata:
  name: fog-site-1
spec:
  # Creates namespace: keycloak-fog-site-1
  ...
```
