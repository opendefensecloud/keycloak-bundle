# Keycloak Solution for Kubernetes

Software-defined Keycloak solution (KeycloakX) for Fog deployment scenarios, packaged as OCM component with Kubernetes-native configuration via Custom Resources.

## Quick Start

```bash
# Deploy
./scripts/deploy-all.sh ms1

# Access Keycloak
./scripts/dev-portforward.sh ms1
# Open http://localhost:8080 (admin/admin)

# Cleanup
./scripts/cleanup.sh ms1
```

## Project Structure

```text
keycloak-solution/
├── manifests/           # Kubernetes manifests
│   ├── keycloak/       # Keycloak deployment
│   └── postgres/       # CloudNativePG cluster
├── charts/             # Helm charts
│   └── keycloak-client-operator/
│       └── crds/       # KeycloakClient CRD
├── ocm/                # OCM component descriptor
├── kro/                # RGD files
├── examples/           # Example resources
├── templates/          # Template files
├── manifests/          # Kubernetes deployment manifest files
├── scripts/            # Deployment scripts
└── docs/               # Documentation
    └── adrs/           # Architecture decisions
```

## Documentation

- [Quickstart](QUICKSTART.md)
- [Deployment Guide](docs/milestone-1/deployment.md)
- [Client CRD Reference](docs/milestone-1/client-crd.md)
- [Architecture Decisions](docs/adrs/)

## Milestones

1. **M1** (31.01.2026) - Proof of Concept (PoC) & initial design review: Delivery of the initial
   OCM package with a basic Keycloak instantiation and the first Custom Resource (CRD) for clients.
   Review of the overall concept including the database strategyBasic instantiation, Client CRD (PoC)
2. **M2** (31.03.2026) - Alpha version: joint testing – OCM package with all necessary CRDs for
   configuring the core functionalities (clients, groups, users, scopes). Testing of multi-instance
   capability and use of KRO.
3. **M3** (30.04.2026) - Final delivery & acceptance: Final acceptance of the OCM package after
   refinement (implementation of day-2 operations, complete documentation, successful security
   check, proof of backup/restore).

## License

Apache 2.0
