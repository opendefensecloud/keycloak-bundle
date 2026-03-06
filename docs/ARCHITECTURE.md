# Architecture

This document describes the Keycloak-specific architecture within the OCM/KRO ecosystem. For the general OCM packaging and KRO instantiation patterns shared across the project family, refer to the central platform documentation.

## Overview

The Keycloak OCM component bundles everything needed to deploy and operate one or more isolated Keycloak instances on Kubernetes -- including the identity server itself, its database backend, and the configuration layer. A single OCM component archive is the unit of distribution, transfer, and deployment.

```text
OCM Component
├── Container Images
│   ├── Keycloak
│   ├── PostgreSQL
│   └── Keycloak Operator
├── Helm Charts
│   └── keycloak-client-operator
├── KRO ResourceGraphDefinition
├── Kubernetes Manifests
└── Documentation
```

## Multi-Instance Model

Each Keycloak instance runs in its own Kubernetes namespace following the pattern `keycloak-<instance-name>`. This namespace-per-instance approach provides strong isolation without requiring separate clusters.

```text
Cluster
├── keycloak-site-1/        # Instance "site-1"
│   ├── PostgreSQL (CNPG)
│   ├── Keycloak
│   └── Client Operator
├── keycloak-site-2/        # Instance "site-2"
│   ├── PostgreSQL (CNPG)
│   ├── Keycloak
│   └── Client Operator
└── cnpg-system/            # CloudNativePG operator (cluster-wide, installed once)
```

Isolation boundaries per namespace:

- **Data** -- dedicated PostgreSQL cluster, no shared database
- **Configuration** -- namespace-scoped CRDs, independent realms and clients
- **Network** -- prepared default-deny NetworkPolicies (enforcement planned)
- **Access** -- RBAC scoped to the instance namespace
- **Resources** -- per-namespace quotas (planned)

Lifecycle is straightforward: deleting the namespace removes the entire instance cleanly.

## KRO Instantiation

A `KeycloakInstance` custom resource triggers KRO to create the namespace and all contained resources. The KRO ResourceGraphDefinition (RGD) encodes the dependency graph so that resources are created in the correct order.

```yaml
apiVersion: kro.run/v1alpha1
kind: KeycloakInstance
metadata:
  name: site-1
spec:
  # KRO creates namespace keycloak-site-1 and deploys all resources into it
```

## Startup Sequence

The deployment uses init containers and readiness checks to guarantee correct startup order and avoid crash loops:

```text
1. CloudNativePG operator ready (cluster-wide, prerequisite)
2. PostgreSQL Cluster created (CNPG CR in instance namespace)
3. Primary pod reaches Ready state (label: cnpg.io/instanceRole=primary)
4. Keycloak Deployment applied
5. Init container wait-for-db confirms port 5432 is reachable
6. Keycloak main container starts
```

## Declarative Configuration

Keycloak configuration (realms, clients, users, roles) is managed declaratively through Kubernetes Custom Resources. The CRD hierarchy follows the Keycloak domain model:

```text
KeycloakInstance (via KRO)
└── KeycloakRealm
    ├── KeycloakClient
    ├── KeycloakUser
    ├── KeycloakGroup
    └── KeycloakClientScope
```

All configuration CRDs are namespace-scoped, aligning with the multi-instance isolation model. This enables standard GitOps workflows with tools like ArgoCD or Flux.

See [USAGE.md](USAGE.md) for usage details and examples, and [CLIENT.md](CLIENT.md) for the implementation strategy and decision record.

## High Availability & Scalability

Both Keycloak and the PostgreSQL backend support multi-replica deployments for production use.

### Keycloak Replicas

The replica count is controlled via the `KeycloakInstance` CR (KRO path) or the `replicas` field in the Keycloak Deployment:

```yaml
# KeycloakInstance CR
spec:
  replicas: 3   # 3 Keycloak pods
```

The Deployment is configured with `maxUnavailable: 0` and `maxSurge: 1` — a new pod must pass the readiness probe on management port 9000 before any old pod is terminated, ensuring zero dropped requests during restarts.

A `PodDisruptionBudget` with `minAvailable: 1` prevents Kubernetes from evicting all Keycloak pods simultaneously during node drains or cluster maintenance.

#### Cluster Session Sharing

With `replicas > 1`, Keycloak activates Infinispan distributed caching (`KC_CACHE_STACK=kubernetes`) so that sessions created on one pod are valid on all others. This uses the Kubernetes JGroups KUBE_PING discovery protocol, which requires Keycloak pods to be able to list pods in their namespace. A dedicated `ServiceAccount` (`keycloak`) with a namespace-scoped `Role` and `RoleBinding` provides this access.

### PostgreSQL HA

CloudNativePG manages streaming replication between PostgreSQL instances automatically. The `dbInstances` field in the `KeycloakInstance` CR controls the cluster size:

```yaml
spec:
  dbInstances: 3   # primary + 2 standbys
```

The `keycloak-db-rw` service always points to the current primary. CNPG performs automatic failover if the primary fails.

### Operator Instance Scoping

The operator is deployed per-instance inside the instance namespace and watches only its own namespace (`WATCH_NAMESPACE` is set to the pod's own namespace via `fieldRef`). This means each instance runs an independent operator process — no cross-instance interference is possible, and there is no need for cluster-wide leader election.

---

## OCM Packaging

The entire solution ships as a single OCM component containing all container images, Helm charts, manifests, and the KRO RGD. This enables:

- **Air-gapped deployment** -- all artifacts are bundled, no external registry access required at deploy time
- **Reproducibility** -- pinned versions for every dependency
- **Transfer** -- `ocm transfer` moves the component between registries
- **Signing** -- component integrity verified via `ocm sign`

## Decision Record

### OCM Packaging Strategy

*Decision: Package the Keycloak solution as a single OCM component containing all dependencies.*

The OCM standard is a project-wide requirement for air-gapped deployment. Bundling everything into one component -- container images, Helm charts, KRO RGD, manifests, and documentation -- gives a single deployable unit that can be transferred between registries, version-tracked, and validated as a whole. The alternative of splitting into multiple OCM components was rejected because it adds coordination overhead without meaningful benefit for a solution of this size.

Component structure:

```text
component-constructor.yaml
├── keycloak-image (ociImage)
├── postgres-image (ociImage)
├── operator-image (ociImage)
├── operator-chart (helmChart)
├── keycloak-instance-rgd (blueprint)
├── manifests (directory)
└── docs (directory)
```

### Multi-Instance Isolation via Namespaces

*Decision: Use Kubernetes namespaces as the primary isolation boundary, one namespace per KeycloakInstance.*

Namespaces are the natural Kubernetes-native isolation mechanism. They provide RBAC scoping, NetworkPolicy boundaries, and resource quotas without additional tooling. The namespace-per-instance pattern (`keycloak-<instance-name>`) keeps the mental model simple and makes cleanup trivial (delete the namespace). The trade-off is a potentially large number of namespaces in clusters with many instances, but this is well within Kubernetes operational limits.

## Related Documents

| Topic | Document |
|-------|----------|
| PostgreSQL with CloudNativePG | [DATABASE.md](DATABASE.md) |
| Operator usage guide | [USAGE.md](USAGE.md) |
| Operator strategy & ADR | [CLIENT.md](CLIENT.md) |
| CI/CD pipeline | [CICD.md](CICD.md) |
