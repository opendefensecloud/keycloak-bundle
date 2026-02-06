# Keycloak Deployment Scripts

This directory contains shell scripts for deploying and managing Keycloak instances
with PostgreSQL persistence on Kubernetes.

## Quick Start

```bash
# Deploy a complete Keycloak instance (auto-generates dev-<random> name)
./scripts/deploy-all.sh
# Output: "No instance name provided, using: dev-a7x2k"

# Or deploy with a specific name (e.g., milestone 1)
./scripts/deploy-all.sh ms1

# Access Keycloak (use the instance name from deploy output)
./scripts/dev-portforward.sh dev-a7x2k
# Open http://localhost:8080 (admin/admin)

# Check status
./scripts/dev-status.sh dev-a7x2k

# Remove instance
./scripts/cleanup.sh dev-a7x2k
```

## Naming Convention

Instance names follow a project lifecycle convention:

| Name Pattern | Purpose | Example Namespace |
| ------------ | ------- | ----------------- |
| `dev-<random>` | Development instances (auto-generated) | `keycloak-dev-a7x2k` |
| `poc` | Proof of concept | `keycloak-poc` |
| `ms1`, `ms2`, `ms3` | Milestone releases | `keycloak-ms1` |
| `alpha`, `beta` | Pre-release stages | `keycloak-alpha` |
| `final` | Production release | `keycloak-final` |
| `<custom>` | Any custom name | `keycloak-mytest` |

**Important:** Milestone names (`ms1`, `ms2`, etc.) are reserved for specific project phases.
Use `dev-*` names or custom names for development and testing.

---

## Script Categories

### Top-Level Scripts (Main Entry Points)

These are the primary scripts you'll use most often:

| Script | Purpose | Usage |
| ------ | ------- | ----- |
| `deploy-all.sh` | Deploy complete Keycloak instance | `./deploy-all.sh [instance]` |
| `cleanup.sh` | Remove a single instance | `./cleanup.sh <instance>` |
| `cleanup-all.sh` | Remove ALL instances and CRDs | `./cleanup-all.sh` |

#### deploy-all.sh

Main deployment script that orchestrates everything:

1. Installs CloudNativePG operator (if not present)
2. Creates namespace `keycloak-<instance>`
3. Deploys PostgreSQL cluster
4. Deploys Keycloak with PostgreSQL persistence

```bash
./scripts/deploy-all.sh              # Auto-generates: keycloak-dev-<random>
./scripts/deploy-all.sh ms1          # Creates: keycloak-ms1 (milestone 1)
./scripts/deploy-all.sh poc          # Creates: keycloak-poc
./scripts/deploy-all.sh mytest       # Creates: keycloak-mytest
```

#### cleanup.sh

Removes a single instance (requires instance name):

```bash
./scripts/cleanup.sh dev-a7x2k       # Remove keycloak-dev-a7x2k
./scripts/cleanup.sh ms1             # Remove keycloak-ms1
```

#### cleanup-all.sh

Removes ALL keycloak-* namespaces (interactive confirmation required):

```bash
./scripts/cleanup-all.sh             # Prompts for confirmation
```

---

### Helper Scripts (Standalone & Subroutine)

These scripts can be run standalone but are also called by top-level scripts:

| Script | Purpose | Called By |
| ------ | ------- | --------- |
| `deploy-postgres.sh` | Deploy PostgreSQL cluster | `deploy-all.sh`, `deploy-instance.sh` |
| `deploy-keycloak.sh` | Deploy Keycloak server | `deploy-all.sh`, `deploy-instance.sh` |
| `deploy-instance.sh` | Deploy PostgreSQL + Keycloak (no CNPG check) | - |
| `deploy-operator.sh` | Deploy Keycloak Client Operator | - |
| `install-cnpg.sh` | Install CloudNativePG operator | `deploy-all.sh` |
| `ocm-create.sh` | Create OCM archive for air-gapped deployment | - |
| `ocm-transfer.sh` | Transfer OCM archive to registry | - |

#### deploy-postgres.sh

Deploys a CloudNativePG PostgreSQL cluster (requires namespace):

```bash
./scripts/deploy-postgres.sh keycloak-ms1
./scripts/deploy-postgres.sh keycloak-dev-a7x2k
```

Creates:

- Namespace (if not exists)
- CloudNativePG Cluster `keycloak-db`
- Secret `keycloak-db-app` (auto-generated credentials)
- Services: `keycloak-db-rw`, `keycloak-db-r`

#### deploy-keycloak.sh

Deploys Keycloak (requires namespace, PostgreSQL must be running):

```bash
./scripts/deploy-keycloak.sh keycloak-ms1
./scripts/deploy-keycloak.sh keycloak-dev-a7x2k
```

Creates:

- Deployment `keycloak`
- Service `keycloak` (ports 8080, 8443)
- Secret `keycloak-admin`

#### install-cnpg.sh

One-time cluster-wide installation of CloudNativePG operator:

```bash
./scripts/install-cnpg.sh              # Install v1.22.0 (default)
./scripts/install-cnpg.sh 1.23.0       # Install specific version
```

#### ocm-create.sh

Creates an OCM component archive using `ocm/component-descriptor.yaml`:

```bash
./scripts/ocm-create.sh                    # Output to ./ocm-output
```

Bundles all images and resources defined in the descriptor.

#### ocm-transfer.sh

Transfers the component archive to a registry (e.g. Harbor):

```bash
./scripts/ocm-transfer.sh [archive-path] [target-registry]
```

Supports interactive prompt for credentials if not provided via flags.

---

### Development Helper Scripts

Scripts for day-to-day development and debugging (all require instance name):

| Script | Purpose | Usage |
| ------ | ------- | ----- |
| `dev-logs.sh` | Stream logs from pods | `./dev-logs.sh <instance> [component]` |
| `dev-portforward.sh` | Port-forward for local access | `./dev-portforward.sh <instance> [port]` |
| `dev-status.sh` | Show instance status | `./dev-status.sh <instance>` |

#### dev-logs.sh

```bash
./scripts/dev-logs.sh dev-a7x2k              # Keycloak logs
./scripts/dev-logs.sh ms1 keycloak           # Keycloak logs (explicit)
./scripts/dev-logs.sh ms1 postgres           # PostgreSQL logs
./scripts/dev-logs.sh poc db                 # PostgreSQL logs (alias)
```

#### dev-portforward.sh

```bash
./scripts/dev-portforward.sh dev-a7x2k       # Forward to localhost:8080
./scripts/dev-portforward.sh ms1 9090        # Forward to custom port
```

#### dev-status.sh

```bash
./scripts/dev-status.sh ms1                  # Show status of keycloak-ms1
./scripts/dev-status.sh dev-a7x2k            # Show status of dev instance
```

Shows: namespace, PostgreSQL cluster health, pods, services.

---

### Utility Scripts

| Script | Purpose | Usage |
| ------ | ------- | ----- |
| `init-dirs.sh` | Recreate directory structure | `./init-dirs.sh` |

---

### Library (Sourced by Other Scripts)

- `common.sh` — Shared functions: `info`, `warn`, `fail`, `generate_suffix`

**Do not execute directly** - this file is sourced by all other scripts:

```bash
source "$SCRIPT_DIR/common.sh"

info "This is informational"       # [INFO] This is informational
warn "This is a warning"           # [WARN] This is a warning
fail "Error message" 2             # [FAIL] Error message (exits with code 2)
SUFFIX=$(generate_suffix)          # Returns random 5-char suffix (e.g., "a7x2k")
```

---

## Architecture

```text
deploy-all.sh [instance]
    ├── install-cnpg.sh (if needed)
    ├── deploy-postgres.sh keycloak-<instance>
    │   └── manifests/postgres/cluster.yaml
    └── deploy-keycloak.sh keycloak-<instance>
        └── manifests/keycloak/*.yaml

cleanup.sh <instance>
    └── kubectl delete namespace keycloak-<instance>

cleanup-all.sh
    └── kubectl delete namespace keycloak-* (all)
```

## Listing Instances

To see all deployed Keycloak instances:

```bash
kubectl get ns | grep keycloak
```

## Prerequisites

- `kubectl` configured with cluster access
- Cluster-admin permissions (for CNPG operator installation)
- `ocm` CLI (only for `ocm-create.sh`)

## Default Values

| Parameter | Default |
| --------- | ------- |
| Instance name | `dev-<random>` (auto-generated) |
| Local port | `8080` |
| Admin username | `admin` |
| Admin password | `admin` |
| PostgreSQL version | 16 |
| Keycloak version | 26.5.0 |
| CloudNativePG version | 1.22.0 |
