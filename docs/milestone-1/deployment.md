# Deployment Guide

## Prerequisites

- Kubernetes cluster (1.28+)
- kubectl configured

## Quick Deployment

```bash
./scripts/deploy-all.sh ms1
```

This will:
1. Install CloudNativePG operator (if needed)
2. Create namespace `keycloak-ms1`
3. Deploy PostgreSQL cluster
4. Deploy Keycloak

## Access Keycloak

```bash
./scripts/dev-portforward.sh ms1
```

Open http://localhost:8080

Login: `admin` / `admin`

## Install Client CRD

```bash
kubectl apply -f charts/keycloak-client-operator/crds/
```

## Scripts

| Script | Purpose |
|--------|---------|
| `deploy-all.sh ms1` | Full deployment |
| `dev-portforward.sh ms1` | Port-forward to Keycloak |
| `dev-status.sh ms1` | Show status |
| `dev-logs.sh keycloak ms1` | Keycloak logs |
| `dev-logs.sh postgres ms1` | PostgreSQL logs |
| `cleanup.sh ms1` | Remove instance |

## Manual Deployment

### 1. Install CloudNativePG

```bash
./scripts/install-cnpg.sh
```

### 2. Deploy PostgreSQL

```bash
./scripts/deploy-postgres.sh keycloak-ms1
```

### 3. Deploy Keycloak

```bash
./scripts/deploy-keycloak.sh keycloak-ms1
```

## Configuration

### Admin Credentials

Edit `manifests/keycloak/keycloak-secret.yaml`:

```yaml
stringData:
  KEYCLOAK_ADMIN_USER: admin
  KEYCLOAK_ADMIN_PASSWORD: <password>
```

### PostgreSQL Storage

Edit `manifests/postgres/cluster.yaml`:

```yaml
spec:
  storage:
    size: 5Gi
```
