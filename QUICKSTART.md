# Quickstart Guide

This guide provides the essential steps to deploy a Keycloak instance on Kubernetes.

## Prerequisites

- Kubernetes cluster (1.28+)
- kubectl configured

## Deployment

### 1. Deploy Instance

```bash
./scripts/deploy-all.sh ms1
```

### 2. Access Keycloak

```bash
./scripts/dev-portforward.sh ms1
```

Open http://localhost:8080

Credentials: `admin` / `admin`

### 3. Install Client CRD

```bash
kubectl apply -f charts/keycloak-client-operator/crds/keycloakclient-crd.yaml

```

### 4. Create Client Resource

```bash
kubectl apply -f examples/client-example.yaml -n keycloak-ms1
kubectl get keycloakclients -n keycloak-ms1
```

## Status and Logs

```bash
./scripts/dev-status.sh ms1
./scripts/dev-logs.sh keycloak ms1
./scripts/dev-logs.sh postgres ms1
```

## Cleanup

```bash
./scripts/cleanup.sh ms1
```

## Further Information

- Architecture: `docs/milestone-1/README.md`
- Deployment details: `docs/milestone-1/deployment.md`
- CRD reference: `docs/milestone-1/client-crd.md`
