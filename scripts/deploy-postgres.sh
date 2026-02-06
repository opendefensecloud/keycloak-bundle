#!/bin/bash
# ==============================================================================
# deploy-postgres.sh - Deploy CloudNativePG PostgreSQL cluster
# ==============================================================================
#
# PURPOSE:
#   Deploys a PostgreSQL database cluster using CloudNativePG operator.
#   Creates the namespace if it doesn't exist and waits for the cluster
#   to become healthy before returning.
#
# USAGE:
#   ./scripts/deploy-postgres.sh <namespace>
#
# ARGUMENTS:
#   namespace   REQUIRED. Target namespace (e.g., "keycloak-ms1")
#
# EXAMPLES:
#   ./scripts/deploy-postgres.sh keycloak-dev-a7x2k   # Dev instance
#   ./scripts/deploy-postgres.sh keycloak-ms1         # Milestone 1
#   ./scripts/deploy-postgres.sh keycloak-poc         # Proof of concept
#
# PREREQUISITES:
#   - CloudNativePG operator must be installed (see install-cnpg.sh)
#   - kubectl configured with cluster access
#
# CREATES:
#   - Namespace (if not exists)
#   - CloudNativePG Cluster "keycloak-db"
#   - Secret "keycloak-db-app" (auto-generated credentials)
#   - Services: keycloak-db-rw (read-write), keycloak-db-r (read-only)
#
# CALLED BY:
#   deploy-all.sh, deploy-instance.sh
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Require namespace
if [[ -z "$1" ]]; then
    fail "Usage: $0 <namespace>\n\nExample: $0 keycloak-ms1\n         $0 keycloak-dev-abc12" 1
fi

NAMESPACE="$1"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

info "Deploying CloudNativePG cluster to namespace: $NAMESPACE"

# Check if CNPG operator is installed
if ! kubectl get crd clusters.postgresql.cnpg.io &>/dev/null; then
    fail "CloudNativePG operator not installed. Run: ./scripts/install-cnpg.sh" 1
fi

# Create namespace if not exists
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - || fail "Failed to create namespace" 2

# Apply CloudNativePG cluster
kubectl apply -n "$NAMESPACE" -f "$PROJECT_ROOT/manifests/postgres/" || fail "Failed to apply PostgreSQL manifests" 3

# Wait for cluster to be ready
info "Waiting for PostgreSQL cluster to be ready..."
info "(This may take a few minutes for first startup)"

for i in {1..60}; do
    STATUS=$(kubectl get cluster keycloak-db -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Pending")
    if [[ "$STATUS" == "Cluster in healthy state" ]]; then
        info "PostgreSQL cluster is ready."
        break
    fi
    if [[ $i -eq 60 ]]; then
        warn "Timeout waiting for cluster. Current status: $STATUS"
    fi
    info "Status: $STATUS (waiting...)"
    sleep 5
done

info "PostgreSQL deployed."
info "Service: keycloak-db-rw.$NAMESPACE.svc:5432"
info "Credentials: kubectl get secret keycloak-db-app -n $NAMESPACE -o yaml"
