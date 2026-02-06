# ADR-001: PostgreSQL as Database Backend with CloudNativePG

**Status:** Accepted  
**Date:** 2026-01-31  
**Decision Makers:** Project Team, Customer

## Context

Keycloak requires a persistent database for storing realms, users, clients, and sessions. For Fog deployment scenarios we need a reliable, self-contained solution that works in isolated environments.

Database options considered:
1. PostgreSQL (external or in-cluster)
2. MySQL/MariaDB
3. Embedded H2 (dev only)

PostgreSQL operator options considered:
1. CloudNativePG (CNCF Sandbox)
2. Zalando Postgres Operator
3. CrunchyData PGO
4. Percona Operator

## Decision

**PostgreSQL** is the database backend, managed by **CloudNativePG** operator.

## Rationale

### PostgreSQL
- Production-proven with Keycloak
- Strong consistency and ACID compliance
- Good performance for IAM workloads
- Customer preference and existing expertise
- Works well in air-gapped/Fog scenarios

### CloudNativePG
- CNCF Sandbox project, active community
- Lightweight, single-binary operator
- Declarative cluster management via CRD
- Good fit for namespace-isolated deployments
- Excellent documentation
- Native Kubernetes integration (no Patroni dependency)
- Supports backup/restore via Barman

Alternatives considered:
- **Zalando**: More complex, Patroni-based, better for large-scale
- **CrunchyData**: Enterprise-focused, heavier footprint
- **Percona**: Newer, less community adoption

## Consequences

### Positive
- Reliable, well-understood technology
- Operator handles failover, backups, updates
- Easy backup/restore with Barman integration
- Good tooling ecosystem
- Per-namespace clusters align with multi-instance isolation

### Negative
- CloudNativePG operator must be installed cluster-wide
- Additional CRDs to manage
- Learning curve for CloudNativePG specifics

## Implementation

### Cluster-Level (once)
```bash
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.22/releases/cnpg-1.22.0.yaml
```

### Per Instance (namespace)
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: keycloak-db
spec:
  instances: 1  # or 3 for HA
  storage:
    size: 5Gi
  bootstrap:
    initdb:
      database: keycloak
      owner: keycloak
```

### Keycloak Connection
- Host: `keycloak-db-rw.<namespace>.svc`
- Port: 5432
- Credentials: Auto-generated in Secret `keycloak-db-app`
