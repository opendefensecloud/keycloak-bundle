#!/bin/bash
# ==============================================================================
# dev-logs.sh - View logs for Keycloak or PostgreSQL
# ==============================================================================
#
# PURPOSE:
#   Streams logs from Keycloak or PostgreSQL pods for debugging and
#   monitoring during development.
#
# USAGE:
#   ./scripts/dev-logs.sh <instance-name> [component]
#
# ARGUMENTS:
#   instance-name   REQUIRED. Instance name (e.g., "dev-a7x2k", "ms1")
#   component       Optional. "keycloak" or "postgres" (default: "keycloak")
#
# EXAMPLES:
#   ./scripts/dev-logs.sh dev-a7x2k              # Keycloak logs
#   ./scripts/dev-logs.sh ms1                    # Keycloak logs from ms1
#   ./scripts/dev-logs.sh ms1 keycloak           # Keycloak logs (explicit)
#   ./scripts/dev-logs.sh ms1 postgres           # PostgreSQL logs
#   ./scripts/dev-logs.sh poc db                 # PostgreSQL logs (alias "db")
#
# NOTES:
#   - Streams last 100 lines and follows new output
#   - Press Ctrl+C to stop
#
# SEE ALSO:
#   dev-status.sh      - Show instance status
#   dev-portforward.sh - Access Keycloak locally
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Require instance name
if [[ -z "$1" ]]; then
    fail "Usage: $0 <instance-name> [keycloak|postgres]\n\nExample: $0 dev-a7x2k\n         $0 ms1 postgres\n\nTo list instances: kubectl get ns | grep keycloak" 1
fi

INSTANCE_NAME="$1"
COMPONENT="${2:-keycloak}"
NAMESPACE="keycloak-$INSTANCE_NAME"

case "$COMPONENT" in
    keycloak)
        SELECTOR="app=keycloak"
        ;;
    postgres|db)
        SELECTOR="cnpg.io/cluster=keycloak-db"
        ;;
    *)
        fail "Unknown component: $COMPONENT\nValid options: keycloak, postgres (or db)" 1
        ;;
esac

info "Showing logs for $COMPONENT in $NAMESPACE"
info "Press Ctrl+C to stop"

kubectl logs -n "$NAMESPACE" -l "$SELECTOR" -f --tail=100 || fail "Failed to get logs" 2
