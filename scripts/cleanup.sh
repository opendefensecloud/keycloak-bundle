#!/bin/bash
# ==============================================================================
# cleanup.sh - Remove a single Keycloak instance
# ==============================================================================
#
# PURPOSE:
#   Deletes a Keycloak instance by removing its entire namespace.
#   This removes PostgreSQL, Keycloak, secrets, and all related resources.
#
# USAGE:
#   ./scripts/cleanup.sh <instance-name>
#
# ARGUMENTS:
#   instance-name   REQUIRED. Name of instance to remove.
#                   Deletes namespace "keycloak-<instance-name>"
#
# NAMING CONVENTION:
#   - dev-<suffix>  : Development instances (e.g., dev-a7x2k)
#   - ms1, ms2, ms3 : Milestone releases
#   - poc           : Proof of concept
#   - alpha, beta   : Pre-release stages
#   - final         : Production release
#
# EXAMPLES:
#   ./scripts/cleanup.sh dev-a7x2k    # Remove keycloak-dev-a7x2k
#   ./scripts/cleanup.sh ms1          # Remove keycloak-ms1
#   ./scripts/cleanup.sh poc          # Remove keycloak-poc
#
# NOTES:
#   - Uses --wait=false for faster return (deletion continues in background)
#   - Safe to run if namespace doesn't exist
#   - Does NOT remove CloudNativePG operator or CRDs
#
# SEE ALSO:
#   cleanup-all.sh - Remove ALL instances and CRDs
#   deploy-all.sh  - Deploy a new instance
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Require instance name
if [[ -z "$1" ]]; then
    fail "Usage: $0 <instance-name>\n\nExample: $0 dev-a7x2k\n         $0 ms1\n\nTo list instances: kubectl get ns | grep keycloak" 1
fi

INSTANCE_NAME="$1"
NAMESPACE="keycloak-$INSTANCE_NAME"

info "=== Cleanup: $INSTANCE_NAME ==="

if kubectl get namespace "$NAMESPACE" &>/dev/null; then
    info "Deleting namespace: $NAMESPACE"
    kubectl delete namespace "$NAMESPACE" --wait=false || warn "Failed to delete namespace"
else
    info "Namespace $NAMESPACE does not exist."
fi

info "Cleanup initiated."
