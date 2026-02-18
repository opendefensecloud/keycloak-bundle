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
#   ./scripts/deploy/cleanup.sh <instance-name>
#
# ARGUMENTS:
#   instance-name   REQUIRED. Name of instance to remove.
#                   Deletes namespace "keycloak-<instance-name>"
#
# NAMING CONVENTION:
#   - poc           : Proof of concept
#   - alpha, beta   : Pre-release stages
#   - final         : Production release
#
# EXAMPLES:
#   ./scripts/deploy/cleanup.sh poc          # Remove keycloak-poc
#
# NOTES:
#   - Uses --wait=false for faster return (deletion continues in background)
#   - Safe to run if namespace doesn't exist
#   - Does NOT remove CloudNativePG operator or CRDs
#
# SEE ALSO:
#   deploy-all.sh  - Deploy a new instance
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

# Require instance name
if [[ -z "$1" ]]; then
    fail "Usage: $0 <instance-name>\n\nExample: $0 poc\n\nTo list instances: kubectl get ns | grep keycloak" 1
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
