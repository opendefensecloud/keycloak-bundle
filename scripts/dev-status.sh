#!/bin/bash
# ==============================================================================
# dev-status.sh - Show status of a Keycloak instance
# ==============================================================================
#
# PURPOSE:
#   Displays the current status of a Keycloak instance including namespace,
#   PostgreSQL cluster health, pods, and services.
#
# USAGE:
#   ./scripts/dev-status.sh <instance-name>
#
# ARGUMENTS:
#   instance-name   REQUIRED. Instance name (e.g., "dev-a7x2k", "ms1")
#
# EXAMPLES:
#   ./scripts/dev-status.sh dev-a7x2k     # Status of dev instance
#   ./scripts/dev-status.sh ms1           # Status of milestone 1
#   ./scripts/dev-status.sh poc           # Status of proof of concept
#
# OUTPUT:
#   - Namespace existence
#   - PostgreSQL cluster status (CloudNativePG)
#   - Pod status (Keycloak and PostgreSQL)
#   - Service endpoints
#
# SEE ALSO:
#   dev-logs.sh        - View logs
#   dev-portforward.sh - Access Keycloak locally
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

info "=== Keycloak Instance: $INSTANCE_NAME ==="

info "--- Namespace ---"
kubectl get namespace "$NAMESPACE" 2>/dev/null || warn "Namespace $NAMESPACE not found"

info "--- PostgreSQL Cluster ---"
kubectl get cluster -n "$NAMESPACE" 2>/dev/null || info "No cluster found"

info "--- Pods ---"
kubectl get pods -n "$NAMESPACE" 2>/dev/null || info "No pods found"

info "--- Services ---"
kubectl get svc -n "$NAMESPACE" 2>/dev/null || info "No services found"
