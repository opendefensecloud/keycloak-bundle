#!/bin/bash
# ==============================================================================
# deploy-operator.sh - Deploy Keycloak Client Operator
# ==============================================================================
#
# PURPOSE:
#   Deploys the Keycloak Client Operator which manages KeycloakClient custom
#   resources. The operator automates client registration in Keycloak.
#
# USAGE:
#   ./scripts/deploy-operator.sh [namespace]
#
# ARGUMENTS:
#   namespace   Optional. Operator namespace (default: "keycloak-operator")
#
# EXAMPLES:
#   ./scripts/deploy-operator.sh                        # Deploy to keycloak-operator
#   ./scripts/deploy-operator.sh keycloak-system        # Custom namespace
#
# CREATES:
#   - Namespace for the operator
#   - CRD: keycloakclients.keycloak.bwi.de
#   - Operator deployment (when templates are complete)
#
# STATUS:
#   The operator implementation is in progress. Currently this script
#   installs the CRDs but the operator deployment may not be complete.
#
# SEE ALSO:
#   charts/keycloak-client-operator/ - Helm chart for the operator
#   examples/client-example.yaml     - Example KeycloakClient resource
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

OPERATOR_NAMESPACE="${1:-keycloak-operator}"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

info "Deploying Keycloak Client Operator to: $OPERATOR_NAMESPACE"

# Create operator namespace
kubectl create namespace "$OPERATOR_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - || fail "Failed to create namespace" 1

# Install CRDs
info "Installing CRDs..."
kubectl apply -f "$PROJECT_ROOT/charts/keycloak-client-operator/crds/" || fail "Failed to install CRDs" 2

# TODO: Replace with Helm install once chart is complete
info "Deploying operator..."
if [[ -d "$PROJECT_ROOT/charts/keycloak-client-operator/templates/" ]]; then
    kubectl apply -n "$OPERATOR_NAMESPACE" -f "$PROJECT_ROOT/charts/keycloak-client-operator/templates/" || warn "No operator templates found yet"
fi

info "Waiting for operator to be ready..."
if kubectl wait -n "$OPERATOR_NAMESPACE" --for=condition=ready pod -l app=keycloak-client-operator --timeout=120s 2>/dev/null; then
    info "Operator deployed and ready."
else
    warn "Operator not deployed yet (templates may be missing)."
fi

info "CRDs installed. Operator deployment pending implementation."
