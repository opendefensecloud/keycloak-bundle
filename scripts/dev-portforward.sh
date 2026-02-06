#!/bin/bash
# ==============================================================================
# dev-portforward.sh - Port-forward Keycloak for local access
# ==============================================================================
#
# PURPOSE:
#   Creates a port-forward from your local machine to the Keycloak service
#   running in Kubernetes. Allows accessing Keycloak UI at localhost.
#
# USAGE:
#   ./scripts/dev-portforward.sh <instance-name> [local-port]
#
# ARGUMENTS:
#   instance-name   REQUIRED. Instance name (e.g., "dev-a7x2k", "ms1")
#   local-port      Optional. Local port to use (default: 8080)
#
# EXAMPLES:
#   ./scripts/dev-portforward.sh dev-a7x2k        # Forward to localhost:8080
#   ./scripts/dev-portforward.sh ms1              # Forward ms1 to :8080
#   ./scripts/dev-portforward.sh poc 9090         # Forward to custom port :9090
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
#   dev-logs.sh   - View logs
#   dev-status.sh - Check instance status
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Require instance name
if [[ -z "$1" ]]; then
    fail "Usage: $0 <instance-name> [local-port]\n\nExample: $0 dev-a7x2k\n         $0 ms1 9090\n\nTo list instances: kubectl get ns | grep keycloak" 1
fi

INSTANCE_NAME="$1"
NAMESPACE="keycloak-$INSTANCE_NAME"
LOCAL_PORT="${2:-8080}"

info "Port-forwarding Keycloak from $NAMESPACE to localhost:$LOCAL_PORT"
info "Press Ctrl+C to stop"
info ""
info "Open: http://localhost:$LOCAL_PORT"

kubectl port-forward -n "$NAMESPACE" svc/keycloak "$LOCAL_PORT:8080" || fail "Port-forward failed" 1
