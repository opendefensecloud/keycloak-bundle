#!/bin/bash
# ==============================================================================
# portforward.sh - Port-forward Keycloak for local access
# ==============================================================================
#
# PURPOSE:
#   Creates a port-forward from your local machine to the Keycloak service
#   running in Kubernetes. Allows accessing Keycloak UI at localhost.
#
# USAGE:
#   ./scripts/utils/portforward.sh <instance-name> [local-port]
#
# ARGUMENTS:
#   instance-name   REQUIRED. Instance name (e.g., "poc", "alpha")
#   local-port      Optional. Local port to use (default: 8080)
#
# EXAMPLES:
#   ./scripts/utils/portforward.sh poc               # Forward to localhost:8080
#   ./scripts/utils/portforward.sh poc 9090         # Forward to custom port :9090
#
# ACCESS:
#   After running, open: http://localhost:<port>
#   Default credentials: admin / admin
#
# NOTES:
#   - Press Ctrl+C to stop the port-forward
#   - Only one port-forward can use a port at a time
#
# SEE ALSO:
#   logs.sh   - View logs
#   status.sh - Check instance status
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Require instance name
if [[ -z "$1" ]]; then
    fail "Usage: $0 <instance-name> [local-port]\n\nExample: $0 poc\n         $0 poc 9090\n\nTo list instances: kubectl get ns | grep keycloak" 1
fi

INSTANCE_NAME="$1"
NAMESPACE="keycloak-$INSTANCE_NAME"
LOCAL_PORT="${2:-8080}"

info "Port-forwarding Keycloak from $NAMESPACE to localhost:$LOCAL_PORT"
info "Press Ctrl+C to stop"
info ""
info "Open: http://localhost:$LOCAL_PORT"

kubectl port-forward -n "$NAMESPACE" svc/keycloak "$LOCAL_PORT:8080" || fail "Port-forward failed" 1
