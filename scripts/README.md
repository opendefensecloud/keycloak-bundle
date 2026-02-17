# Keycloak Deployment Scripts

This directory contains shell scripts for building, deploying, and verifying the Keycloak OCM component.
Scripts are designed to be portable and are used across manual CLI workflows and GitHub Actions.

## Directory Structure

| Directory | Purpose |
| :--- | :--- |
| `ocm/` | **Packaging**: Create, sign, and transfer OCM components. |
| `deploy/` | **Deployment**: Deploy Keycloak to Kubernetes. |
| `utils/` | **Utilities**: Status checks, logs, port-forwarding, and shared libraries. |
| `tests/` | **Verification**: Scripts for testing CRDs and deployments. |

## Prerequisites

Before running these scripts, ensure you have:

*   **Tools**:
    *   `kubectl` (latest version recommended)
    *   `ocm` CLI (for packaging/signing)
*   **Access**:
    *   A Kubernetes cluster (Kubeconfig configured)
    *   **Cluster-Admin** permissions (required for installing CNPG Operator & CRDs)
    *   Registry credentials (if pushing/pulling OCM components)

## Quick Start

```bash
# 1. Deploy a complete Keycloak instance
./scripts/deploy/deploy-all.sh

# 2. Check status
./scripts/utils/status.sh dev-<random-id>

# 3. Port-forward (localhost:8080)
./scripts/utils/portforward.sh dev-<random-id>
```

## Script Compatibility Matrix

| Script | CLI (Manual) | GitHub Actions | Description |
| :--- | :---: | :---: | :--- |
| **OCM Packaging** | | | |
| `ocm/ocm-create.sh` | ✅ | ✅ | Creates the component archive (CTF tarball). |
| `ocm/ocm-sign.sh` | ✅ | ✅ | Signs the archive (uses `ocm-key.priv`). |
| `ocm/ocm-validate.sh` | ✅ | ✅ | Validates structure and signatures. |
| `ocm/ocm-transfer.sh` | ✅ | ✅ | Transfers archive to OCI registry. |
| **Deployment** | | | |
| `deploy/deploy-all.sh` | ✅ | ✅ | **Main Entry Point**: Deploys full stack (CNPG + Keycloak + Operator). |
| `deploy/cleanup.sh` | ✅ | ✅ | Removes a specific instance/namespace. |
| `deploy/install-cnpg.sh` | ✅ | ✅ | Installs CNPG operator (idempotent; checks first). |
| `utils/status.sh` | ✅ | ✅ | **Smoke Test**: Checks Pods, Services, and HTTP Health. |
| `tests/test-crd.sh` | ✅ | ✅ | **Verification**: Tests `KeycloakClient` CRD functionality. |
| **Helpers** | | | |
| `utils/logs.sh` | ✅ | ❌ | Streams logs (interactive/debug only). |
| `utils/portforward.sh` | ✅ | ❌ | Opens localhost tunnel (interactive only). |
| `utils/common.sh` | 🔒 | 🔒 | Library sourced by other scripts. |

## CI/CD Reference Implementation

### GitHub Actions (Primary)
The `.github/workflows/ci.yml` is the primary pipeline for this project. It runs on every commit/PR and performs:
1. Linting (YAML, ShellCheck, Gitleaks)
2. Build & Sign (OCM)
3. Transfer (to OCI Registry)
4. Deploy & Verify (Smoke Tests)

## Usage Examples

### 1. Build & Transfer (OCM)
```bash
# Create and Sign
./scripts/ocm/ocm-create.sh
./scripts/ocm/ocm-sign.sh

# Transfer to Registry
./scripts/ocm/ocm-transfer.sh --user <user> --password <pass>
```

### 2. Deploy to Cluster
```bash
# Deploy a new instance named 'dev-1'
./scripts/deploy/deploy-all.sh dev-1
```

### 3. Verify
```bash
# Check Status
./scripts/utils/status.sh dev-1

# Run CRD Tests
./scripts/tests/test-crd.sh keycloak-dev-1
```

### 4. Cleanup
```bash
./scripts/deploy/cleanup.sh dev-1
```

## Architecture

```text
Run: ./scripts/deploy/deploy-all.sh [instance]
  ├── [1] Checks/Installs CloudNativePG Operator (install-cnpg.sh)
  ├── [2] Deploys PostgreSQL Cluster (deploy-postgres.sh)
  ├── [3] Deploys Keycloak (deploy-keycloak.sh)
  └── [4] Deploys Client Operator (deploy-operator.sh)
```
