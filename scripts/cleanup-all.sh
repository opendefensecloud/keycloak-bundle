#!/bin/bash
# ==============================================================================
# cleanup-all.sh - Remove ALL Keycloak instances and CRDs
# ==============================================================================
#
# PURPOSE:
#   Complete cleanup of all Keycloak-related resources across the cluster.
#   Removes all keycloak-* namespaces and the KeycloakClient CRD.
#
# USAGE:
#   ./scripts/cleanup-all.sh
#
# EXAMPLES:
#   ./scripts/cleanup-all.sh       # Interactive confirmation required
#
# WARNING:
#   This is a destructive operation! It will:
#   - Delete ALL namespaces matching "keycloak-*"
#   - Delete the KeycloakClient CRD (and all KeycloakClient resources)
#   - Requires interactive confirmation (y/N prompt)
#
# DOES NOT REMOVE:
#   - CloudNativePG operator (in cnpg-system namespace)
#   - CloudNativePG CRDs
#
# SEE ALSO:
#   cleanup.sh - Remove a single instance
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

info "=== Full Cleanup ==="
warn "This will delete ALL keycloak namespaces and CRDs!"

read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Aborted."
    exit 0
fi

# Find and delete all keycloak namespaces
for ns in $(kubectl get namespaces -o name | grep keycloak | cut -d/ -f2); do
    info "Deleting namespace: $ns"
    kubectl delete namespace "$ns" --wait=false || warn "Failed to delete $ns"
done

# Delete CRDs
info "Deleting CRDs..."
kubectl delete crd keycloakclients.keycloak.bwi.de 2>/dev/null || info "CRD not found."

info "Full cleanup initiated."
