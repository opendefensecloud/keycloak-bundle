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
#   ./scripts/deploy/deploy-operator.sh [namespace]
#
# ARGUMENTS:
#   namespace   Optional. Operator namespace (default: "keycloak-operator")
#
# EXAMPLES:
#   ./scripts/deploy/deploy-operator.sh                        # Deploy to keycloak-operator
#   ./scripts/deploy/deploy-operator.sh keycloak-system        # Custom namespace
#
# CREATES:
#   - Namespace for the operator
#   - CRD: keycloakclients.keycloak.ocm.software
#   - Operator deployment (when templates are complete)
#
# STATUS:
#   Operator is implemented (Bash-based controller).
#
# SEE ALSO:
#   charts/keycloak-client-operator/ - Helm chart for the operator
#   examples/client-example.yaml     - Example KeycloakClient resource
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

OPERATOR_NAMESPACE="${1:-keycloak-operator}"
PROJECT_ROOT="$(cd "$(dirname "$(dirname "$SCRIPT_DIR")")" && pwd)"

info "Deploying Keycloak Client Operator to: $OPERATOR_NAMESPACE"

# Create operator namespace
kubectl create namespace "$OPERATOR_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - || fail "Failed to create namespace" 1

# Install CRDs
info "Installing CRDs..."
kubectl apply -f "$PROJECT_ROOT/charts/keycloak-client-operator/crds/" || fail "Failed to install CRDs" 2

# Check for helm
if ! command -v helm &> /dev/null; then
    fail "Helm is not installed. Please install helm first." 1
fi

# Deploy operator using Helm
info "Deploying operator with Helm..."
helm upgrade --install keycloak-client-operator "$PROJECT_ROOT/charts/keycloak-client-operator" \
    --namespace "$OPERATOR_NAMESPACE" \
    --create-namespace \
    --wait \
    --timeout 120s || fail "Failed to deploy operator chart" 3

info "Operator deployed and ready."
info "Operator and CRDs installed successfully."
