# Upgrade Runbook

This document describes how to safely upgrade the components of the Keycloak OCM bundle.

---

## General Principles

- Always upgrade one component at a time and verify health before proceeding.
- Take a database backup before any upgrade that touches Keycloak or PostgreSQL.
- All version changes must go through the `component-constructor.yaml` and a new OCM component release.

---

## 1. Keycloak Minor / Patch Version Upgrade

Keycloak handles database schema migrations automatically on startup. Minor and patch upgrades are rolling and safe.

**Steps:**

1. Take a CloudNativePG backup (see section 3).
2. Update the image tag in `manifests/keycloak/keycloak-deployment.yaml` and `component-constructor.yaml`.
3. Commit, push, and let the CI pipeline build and publish the new OCM component version.
4. Apply the updated manifests to the target cluster:
   ```sh
   kubectl apply -f manifests/keycloak/keycloak-deployment.yaml
   ```
5. Verify the rolling update completes:
   ```sh
   kubectl rollout status deployment/keycloak
   ```
6. Confirm health:
   ```sh
   kubectl exec -it deploy/keycloak -- curl -s http://localhost:9000/health/ready
   ```

---

## 2. Keycloak Major Version Upgrade

Major Keycloak upgrades may include breaking DB schema changes and require careful preparation.

**Steps:**

1. Read the upstream [Keycloak migration guide](https://www.keycloak.org/docs/latest/upgrading/) for the target version.
2. Take a CloudNativePG backup (see section 3).
3. Scale Keycloak to 0 replicas to prevent writes during migration:
   ```sh
   kubectl scale deployment keycloak --replicas=0
   ```
4. Update the image tag in both `manifests/keycloak/keycloak-deployment.yaml` and `component-constructor.yaml`.
5. Apply and scale back up:
   ```sh
   kubectl apply -f manifests/keycloak/keycloak-deployment.yaml
   kubectl scale deployment keycloak --replicas=1
   ```
6. Monitor startup logs — Keycloak will run DB migrations automatically:
   ```sh
   kubectl logs -f deploy/keycloak
   ```
7. Verify health endpoints and perform a smoke test (login, token issuance).
8. If migration fails, restore from backup (see section 3) and roll back the image tag.

---

## 3. PostgreSQL Minor Version Upgrade (CloudNativePG)

CloudNativePG handles minor PostgreSQL upgrades as in-place rolling restarts.

**Steps:**

1. Update the `imageName` in `manifests/postgres/cluster.yaml` to the new minor version tag.
2. Apply:
   ```sh
   kubectl apply -f manifests/postgres/cluster.yaml
   ```
3. CloudNativePG will perform a rolling restart of the cluster instances.
4. Verify the cluster is healthy:
   ```sh
   kubectl get cluster keycloak-db
   kubectl describe cluster keycloak-db
   ```

---

## 4. PostgreSQL Major Version Upgrade (CloudNativePG)

Major PostgreSQL upgrades (e.g., 17 → 18) require a cluster clone + switchover procedure via CloudNativePG's `pg_upgrade` support.

**Steps:**

1. Ensure a recent backup exists:
   ```sh
   kubectl get backup -l cnpg.io/cluster=keycloak-db
   ```
2. Create a new cluster manifest (`manifests/postgres/cluster-new.yaml`) targeting the new major version with `bootstrap.pg_upgrade` pointing to the existing cluster.
3. Apply the new cluster — CloudNativePG will handle `pg_upgrade` in-place:
   ```sh
   kubectl apply -f manifests/postgres/cluster-new.yaml
   ```
4. Monitor the upgrade job:
   ```sh
   kubectl logs -l cnpg.io/cluster=keycloak-db-new -f
   ```
5. Once complete and healthy, update Keycloak's `KC_DB_URL_HOST` to point to the new cluster's service and restart Keycloak.
6. Decommission the old cluster only after verifying full functionality.

Reference: [CloudNativePG Major Upgrades](https://cloudnative-pg.io/documentation/current/postgresql_upgrade/)

---

## 5. Taking a Manual Database Backup

CloudNativePG supports on-demand backups. To trigger one:

```sh
kubectl apply -f - <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: keycloak-db-manual-$(date +%Y%m%d%H%M)
spec:
  cluster:
    name: keycloak-db
  method: barmanObjectStore
EOF
```

> Note: Requires an object store (S3-compatible) configured in the Cluster spec. For pre-upgrade safety without an object store, use a volume snapshot if your storage class supports it.

---

## 6. CloudNativePG Operator Upgrade

1. Update the operator image tag in `component-constructor.yaml`.
2. Re-apply the Helm chart or operator manifests per the CloudNativePG upgrade guide.
3. The operator upgrade does not restart database clusters unless a manifest change triggers it.

Reference: [CloudNativePG Operator Upgrade](https://cloudnative-pg.io/documentation/current/installation_upgrade/)

---

## 7. Verifying Observability After Upgrades

After any upgrade, confirm the full observability stack is operational:

```sh
# Check Keycloak metrics endpoint
kubectl exec -it deploy/keycloak -- curl -s http://localhost:9000/metrics | head -20

# Check ServiceMonitor is being scraped (requires Prometheus access)
kubectl get servicemonitor keycloak

# Check PodMonitor for database
kubectl get podmonitor keycloak-db

# Check PrometheusRules loaded
kubectl get prometheusrule keycloak
```

If OTEL tracing is enabled (`KC_TRACING_ENABLED=true`), verify trace data reaches the collector:

```sh
kubectl logs -l app=opentelemetry-collector -n observability | grep keycloak
```
