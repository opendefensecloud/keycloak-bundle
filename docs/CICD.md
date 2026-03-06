# CI/CD Pipeline

This document describes the CI/CD pipeline for the Keycloak OCM component, implemented as a GitHub Actions workflow.

## Pipeline Overview

The pipeline is defined in `.github/workflows/ci.yml` and consists of four sequential stages:

```text
Quality Checks  -->  Build OCM  -->  Transfer  -->  Deploy & Verify
  Lint                 Create          Push to         K8s Deploy
  ShellCheck           Sign            Registry        Smoke Test
  Gitleaks             Validate
```

Each stage builds on the output of the previous one. The pipeline produces a signed, validated OCM component archive, transfers it to an OCI registry, and deploys it to a Kubernetes cluster for verification.

## Triggers

| Trigger | Branches | Behavior |
|---------|----------|----------|
| `push` | `main`, `feature/**`, `fix/**`, `feat/**` | Runs all stages |
| `pull_request` | `main` | Runs all stages |
| `workflow_dispatch` | Any | Manual trigger with selectable stages |

### Manual Trigger

Navigate to **Actions** > **OCM Build & Deploy** > **Run workflow** to trigger a run with individual stage control:

| Input | Default | Description |
|-------|:-------:|-------------|
| `run_lint` | on | YAML Lint, ShellCheck, Gitleaks |
| `run_build` | on | Build, sign, and validate OCM component |
| `run_transfer` | on | Push OCM archive to registry |
| `run_deploy` | on | Deploy to Kubernetes and run smoke tests |

Stages have dependencies. Disabling an earlier stage while enabling a later one will fail unless a cached artifact from a previous run exists. Enable stages left-to-right.

## Required Secrets

Secrets must be configured in GitHub under **Settings > Environments > cicd > Environment secrets**:

| Secret | Used By | Description |
|--------|---------|-------------|
| `KUBECONFIG` | Deploy | Base64-encoded kubeconfig for the target cluster |
| `OCM_REGISTRY` | Transfer | Target OCI registry URL (e.g. `ghcr.io/your-org/keycloak-ocm`) |
| `OCM_REGISTRY_USER` | Transfer | (Optional) Registry username. Defaults to `github.actor`. |
| `OCM_REGISTRY_PASSWORD` | Transfer | (Optional) Registry token. Defaults to `secrets.GITHUB_TOKEN`. |

`OCM_REGISTRY` can alternatively be set as a repository variable (not secret) if it does not need to be hidden. The pipeline checks `vars.OCM_REGISTRY` first, then `secrets.OCM_REGISTRY`, and falls back to `ghcr.io/opendefensecloud/keycloak-ocm`.

### Creating the KUBECONFIG Secret

```bash
# From existing kubeconfig
cat ~/.kube/config | base64 -w 0

# From a specific context
kubectl config view --minify --flatten | base64 -w 0
```

## Deployment Strategy

### CI Environment

In CI the pipeline deploys with `--clean`, which deletes the target namespace before each run:

```bash
./scripts/deploy-all.sh ci --clean
```

This ensures no state drift from previous runs, reproducible test results, and clean database initialization.

### Production / Development

Without `--clean`, existing resources are updated in-place via Kubernetes rolling updates:

```bash
./scripts/deploy-all.sh my-instance
```

### Startup Sequence

The deployment script enforces a strict startup order to avoid crash loops:

1. CloudNativePG operator installed (if missing)
2. PostgreSQL cluster created via CNPG CR
3. Wait for primary pod (`cnpg.io/instanceRole=primary`) to reach Ready
4. Keycloak Deployment applied
5. Init container `wait-for-db` confirms database port 5432 is reachable
6. Keycloak main container starts

## Smoke Tests

After deployment the pipeline verifies the instance is healthy:

1. **PostgreSQL** -- primary pod with label `cnpg.io/instanceRole=primary` is Ready
2. **Keycloak** -- `deployment/keycloak` reaches Available condition
3. **Pod status** -- all pods in the namespace are listed
4. **Health check** -- `curl http://localhost:8080/health/ready` executed inside the Keycloak container

## Troubleshooting

**Pipeline hangs on "Waiting for primary pod..."**

The CNPG label is `cnpg.io/instanceRole=primary` (not `cnpg.io/role=primary`). Verify:

```bash
kubectl get pods -n keycloak-ci --show-labels
```

**Health check returns "executable file not found"**

Ensure `-c keycloak` is specified in the `kubectl exec` command to target the main container, not the `wait-for-db` init container.

**Namespace stuck in Terminating**

```bash
kubectl delete namespace keycloak-ci --force --grace-period=0
```

## Decision Record

*Decision: Use GitHub Actions as the CI/CD platform with a four-stage pipeline (Quality Checks, Build OCM, Transfer, Deploy & Verify).*

The pipeline is designed around the OCM lifecycle: build a component archive, sign and validate it, transfer it to an OCI registry, and deploy it for verification. GitHub Actions was chosen because the project is hosted on GitHub and the workflow integrates directly with repository secrets and events. The `--clean` strategy for CI ensures reproducible runs by deleting the namespace before each deployment, avoiding state drift. Production deployments use in-place rolling updates instead.

The manual trigger (`workflow_dispatch`) with per-stage toggles allows running individual stages during development and debugging without re-running the full pipeline. Stages are intentionally sequential with left-to-right dependencies to match the OCM build-transfer-deploy lifecycle.

## Related Documents

| Topic | Document |
|-------|----------|
| OCM packaging strategy | [ARCHITECTURE.md](ARCHITECTURE.md) |
