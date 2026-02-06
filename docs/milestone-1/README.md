# Milestone 1: Proof of Concept

**Deadline:** 28.02.2026

## Scope

- Initial OCM package with basic Keycloak instantiation
- First Custom Resource (CRD) for Clients
- Design review including database strategy

## Quick Start

```bash
# Deploy
./scripts/deploy-all.sh ms1

# Access
./scripts/dev-portforward.sh ms1
# Open http://localhost:8080 (admin/admin)

# Test CRD
kubectl apply -f charts/keycloak-client-operator/crds/
kubectl apply -f examples/client-example.yaml -n keycloak-ms1

# Cleanup
./scripts/cleanup.sh ms1
```

## Components

| Component | Version | Purpose |
|-----------|---------|---------|
| Keycloak (Quay.io) | 24.0.4 | IAM solution |
| CloudNativePG | 1.22 | PostgreSQL operator |
| PostgreSQL | 16 | Database |

## Architecture

```text
┌─────────────────────────────────────────────┐
│ Namespace: keycloak-ms1                      │
│                                              │
│  ┌─────────────┐    ┌─────────────────────┐ │
│  │  Keycloak   │───▶│  PostgreSQL (CNPG)  │ │
│  │  :8080      │    │  keycloak-db-rw     │ │
│  └─────────────┘    └─────────────────────┘ │
└─────────────────────────────────────────────┘
```

## Deliverables

- `manifests/` - Kubernetes manifests
- `charts/keycloak-client-operator/crds/` - Client CRD
- `ocm/component-descriptor.yaml` - OCM package
- `docs/adrs/` - Architecture decisions

## Out of Scope (Milestone 2+)

- KRO integration
- Multi-instance testing
- Operator implementation
- Additional CRDs (Realm, User, Group)
