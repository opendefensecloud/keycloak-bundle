# Keycloak OCM Solution for Kubernetes

A software-defined Keycloak solution packaged as an Open Component Model (OCM) component for air-gapped and cloud-native Kubernetes deployments. It features Kubernetes-native configuration via Custom Resources (CRDs) and a robust CI/CD pipeline.

## Table of Contents

- [Intention](#intention)
- [Status](#status)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Direct Usage (kubectl / ocm)](#direct-usage-kubectl--ocm)
  - [Helper Scripts](#helper-scripts)
- [Project Structure](#project-structure)
- [Documentation](#documentation)
- [License](#license)

## Intention

This repository contains a **standalone OCM component** for Keycloak, developed as a building block for the [opendefensecloud/ocm-components](https://github.com/opendefensecloud/ocm-components) project. Until integration, it operates independently with its own deployment scripts and CI/CD pipeline.

The goal is to provide a fully reproducible, air-gap-capable Keycloak deployment that can be versioned, signed, and transferred as an OCM component archive. The solution includes a PostgreSQL database (via CloudNativePG), a Keycloak Client Operator for declarative client management, and multi-instance namespace isolation.

> [!NOTE]
> **Integration into opendefensecloud/ocm-components**
>
> In `ocm-components` this solution will be published simply as **keycloak**. Supporting
> software like PostgreSQL and CloudNativePG are separate OCM components in the same
> repository. The KRO ResourceGraphDefinition (RGD) references these companion components
> rather than bundling them, so each dependency is versioned, signed, and transferable
> independently.
>
> For integration the keycloak component archive -- containing the Keycloak container image,
> Kubernetes manifests, the KeycloakClient CRD, and the RGD -- will be transferred into the
> shared OCI registry of `ocm-components`. Deployment then works through KRO: a
> `KeycloakInstance` custom resource triggers the RGD which creates an isolated namespace
> (`keycloak-<instance>`) and orchestrates the full stack -- referencing the PostgreSQL OCM
> component for the database, deploying Keycloak, and starting the client operator -- in the
> correct startup order. Consumer teams never interact with this repository directly; they
> declare `KeycloakClient` CRs in their application repositories and the operator reconciles
> them against the running Keycloak instance, syncing credentials back as Kubernetes Secrets.
>
> Until that integration is complete, this repository operates standalone: it bundles all
> dependencies (including PostgreSQL images) in its own component archive and provides its
> own CI/CD pipeline and helper scripts to build, sign, transfer, and deploy independently.

## Status

| Feature | Status | Description |
|---------|:------:|-------------|
| **OCM Packaging** | done | Component versioning, signing, and transfer |
| **CI Pipeline** | done | GitHub Actions with Lint, Build, Sign, Transfer, Deploy, Smoke Test |
| **Deployment** | done | Script-based deployment of CloudNativePG + Keycloak |
| **Resilience** | done | Init containers (DB wait), liveness probes, primary pod wait logic |
| **Operator** | done | Bash-CD Controller with reconciliation (PUT) and K8s Secret sync |
| **Reproducibility** | done | `--clean` flag for fresh CI environments |
| **Security** | done | Non-root containers, Gitleaks scan, ShellCheck, YAML Lint |

## Prerequisites

- Kubernetes cluster (1.28+)
- `kubectl` configured for the target cluster
- `ocm` CLI (for OCM packaging and transfer)
- [CloudNativePG operator](https://cloudnative-pg.io/) installed in the cluster

## Usage

### Direct Usage (kubectl / ocm)

All resources can be deployed directly with `kubectl` without any helper scripts. Each Keycloak instance lives in its own namespace following the naming convention `keycloak-<instance>`.

#### Deploy PostgreSQL and Keycloak

```bash
# Create instance namespace
INSTANCE="my-test"
NAMESPACE="keycloak-${INSTANCE}"
kubectl create namespace "$NAMESPACE"

# Deploy PostgreSQL (requires CloudNativePG operator)
kubectl apply -f manifests/postgres/cluster.yaml -n "$NAMESPACE"

# Wait for the database to become ready
kubectl wait --for=condition=Ready cluster/keycloak-db -n "$NAMESPACE" --timeout=300s

# Deploy Keycloak (secret, deployment, service)
kubectl apply -f manifests/keycloak/ -n "$NAMESPACE"

# Wait for Keycloak to become available
kubectl wait --for=condition=Available deployment/keycloak -n "$NAMESPACE" --timeout=300s
```

#### Access Keycloak

```bash
# Port-forward to reach the Keycloak UI
kubectl port-forward -n "$NAMESPACE" svc/keycloak 8080:8080

# Open http://localhost:8080
# User: admin
# Get password:
kubectl get secret keycloak-admin -n "$NAMESPACE" \
  -o jsonpath='{.data.KEYCLOAK_ADMIN_PASSWORD}' | base64 -d
```

#### Install Client CRD and Create a Client

```bash
# Install the KeycloakClient CRD
kubectl apply -f charts/keycloak-client-operator/crds/keycloakclient-crd.yaml

# Create an example client
kubectl apply -f examples/client-example.yaml -n "$NAMESPACE"
kubectl get keycloakclients -n "$NAMESPACE"
```

#### OCM Packaging

```bash
# Create component archive
ocm create componentarchive ocm-output/component-archive
ocm add componentversions --create --file ocm-output/component-archive \
  component-constructor.yaml

# Sign, validate, and transfer
ocm sign componentversions --signature keycloak-sig --private-key ocm-key.pem \
  ocm-output/component-archive
ocm transfer componentversions ocm-output/component-archive ghcr.io/<org>/ocm
```

#### Cleanup

```bash
kubectl delete namespace "$NAMESPACE"
```

### Helper Scripts

For local development as well as for CI/CD pipelines helper scripts at `scripts/` exist. They are documented in the [README](scripts/README.md) there.

## Project Structure

```text
keycloak/
├── .github/workflows/          # CI/CD pipeline (ci.yml)
├── manifests/                  # Kubernetes manifests
│   ├── keycloak/               #   Keycloak deployment + init container
│   └── postgres/               #   CloudNativePG cluster
├── charts/                     # Helm charts
│   └── keycloak-client-operator/
│       └── crds/               #   KeycloakClient CRD
├── scripts/                    # Deployment & OCM scripts
├── component-constructor.yaml  # OCM component constructor (definition)
├── kro/                        # KRO Resource Group Definitions
├── examples/                   # Example resources
├── docs/                       # Documentation
└── README.md
```

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | OCM/KRO architecture, multi-instance model, namespace isolation |
| [Database](docs/DATABASE.md) | PostgreSQL with CloudNativePG decision and deployment model |
| [Client Configuration](docs/CLIENT.md) | Declarative configuration approach comparison and keycloak-client-operator |
| [CI/CD Pipeline](docs/CICD.md) | GitHub Actions pipeline, secrets, deployment strategy, troubleshooting |
| [Usage Concept](docs/USAGE-CONCEPT.md) | Keycloak Client Operator architecture, GitOps workflow, and usage guide |

## License

Apache 2.0
