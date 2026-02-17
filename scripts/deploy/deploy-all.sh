#!/bin/bash
# ==============================================================================
# deploy-all.sh - Deploy a complete Keycloak instance with all dependencies
# ==============================================================================
#
# PURPOSE:
#   Main entry point for deploying a fully functional Keycloak instance.
#   This script orchestrates the complete deployment including:
#   - CloudNativePG operator installation (if not present)
#   - PostgreSQL database cluster
#   - Keycloak application server
#
# USAGE:
#   ./scripts/deploy/deploy-all.sh [instance-name]
#
# ARGUMENTS:
#   instance-name   Optional. Name for the instance.
#                   If not provided, generates "dev-<random>" (e.g., dev-a7x2k)
#                   Creates namespace "keycloak-<instance-name>"
#
# NAMING CONVENTION:
#   - dev-<random>  : Development instances (auto-generated default)
#   - ms1, ms2, ms3 : Milestone releases
#   - poc           : Proof of concept
#   - alpha, beta   : Pre-release stages
#   - final         : Production release
#
# EXAMPLES:
#   ./scripts/deploy/deploy-all.sh           # Deploy to keycloak-dev-a7x2k (random)
#   ./scripts/deploy/deploy-all.sh ms1       # Deploy to keycloak-ms1 (milestone 1)
#   ./scripts/deploy/deploy-all.sh poc       # Deploy to keycloak-poc
#   ./scripts/deploy/deploy-all.sh mytest    # Deploy to keycloak-mytest
#
# DEPENDENCIES:
#   - kubectl configured with cluster access
#   - Calls: install-cnpg.sh, deploy-postgres.sh, deploy-keycloak.sh
#
# SEE ALSO:
#   utils/status.sh        - Check instance status
#   utils/portforward.sh   - Access Keycloak locally
#   cleanup.sh             - Remove a single instance
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

PROJECT_ROOT="$(cd "$(dirname "$(dirname "$SCRIPT_DIR")")" && pwd)"
info "Project Root: $PROJECT_ROOT"

# Generate random suffix if no instance name provided
# Parse arguments
INSTANCE_NAME=""
CLEAN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -*)
            fail "Unknown option: $1" 1
            ;;
        *)
            if [[ -z "$INSTANCE_NAME" ]]; then
                INSTANCE_NAME="$1"
            else
                fail "Multiple instance names provided" 1
            fi
            shift
            ;;
    esac
done

# Generate random suffix if no instance name provided
if [[ -z "$INSTANCE_NAME" ]]; then
    INSTANCE_NAME="dev-$(generate_suffix)"
    info "No instance name provided, using: $INSTANCE_NAME"
fi

NAMESPACE="keycloak-$INSTANCE_NAME"

if [[ "$CLEAN" == "true" ]]; then
    info "Cleanup requested for instance: $INSTANCE_NAME"
    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
        "$SCRIPT_DIR/cleanup.sh" "$INSTANCE_NAME"
        info "Waiting for namespace deletion..."
        kubectl wait --for=delete namespace/"$NAMESPACE" --timeout=300s || true
    else
        info "Namespace $NAMESPACE already gone."
    fi
fi

info "=== Deploying Keycloak Instance: $INSTANCE_NAME ==="
info "Namespace: $NAMESPACE"

# Check/install CloudNativePG
if ! kubectl get crd clusters.postgresql.cnpg.io &>/dev/null; then
    info "CloudNativePG not found. Installing..."
    "$SCRIPT_DIR/install-cnpg.sh" || fail "CloudNativePG installation failed" 1
fi

# Deploy PostgreSQL
"$SCRIPT_DIR/deploy-postgres.sh" "$NAMESPACE" || fail "PostgreSQL deployment failed" 2

# Deploy Keycloak
"$SCRIPT_DIR/deploy-keycloak.sh" "$NAMESPACE" || fail "Keycloak deployment failed" 3

# Deploy Client Operator
"$SCRIPT_DIR/deploy-operator.sh" "$NAMESPACE" || fail "Client Operator deployment failed" 4

info "=== Deployment complete ==="
info ""
info "Instance name: $INSTANCE_NAME"
info ""
info "Next steps:"
info "  1. Port-forward: ./scripts/utils/portforward.sh $INSTANCE_NAME"
info "  2. Open: http://localhost:8080 (admin/admin)"
info "  3. Install CRD: kubectl apply -f charts/keycloak-client-operator/crds/"
info "  4. Create client: kubectl apply -f examples/client-example.yaml -n $NAMESPACE"
info ""
info "To remove this instance:"
info "  ./scripts/deploy/cleanup.sh $INSTANCE_NAME"
