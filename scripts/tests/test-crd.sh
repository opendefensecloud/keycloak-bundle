#!/bin/bash
# ==============================================================================
# test-crd.sh - Verify KeycloakClient CRD functionality
# ==============================================================================
#
# PURPOSE:
#   Tests the end-to-end flow of the Keycloak Client Operator:
#   1. Applies a KeycloakClient CR
#   2. Waits for the operator to process it
#   3. Verifies the client exists in Keycloak (via kcadm.sh)
#
# USAGE:
#   ./scripts/tests/test-crd.sh <namespace>
#
# EXAMPLE:
#   ./scripts/tests/test-crd.sh keycloak-poc
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

NAMESPACE="${1:-}"

if [[ -z "$NAMESPACE" ]]; then
    fail "Usage: $0 <namespace>" 1
fi

PROJECT_ROOT="$(cd "$(dirname "$(dirname "$SCRIPT_DIR")")" && pwd)"
CLIENT_CR_FILE="$PROJECT_ROOT/examples/client-example.yaml"
CLIENT_ID="ocm-poc-client"

info "Testing KeycloakClient CRD in namespace: $NAMESPACE"

# 1. Check prerequisites
info "Checking Keycloak and Operator status..."
kubectl wait --for=condition=ready pod -l app=keycloak -n "$NAMESPACE" --timeout=60s || fail "Keycloak not ready"
kubectl wait --for=condition=ready pod -l app=keycloak-client-operator -n "$NAMESPACE" --timeout=60s || fail "Operator not ready"

# 2. Get Keycloak Pod and Credentials
KEYCLOAK_POD=$(kubectl get pod -n "$NAMESPACE" -l app=keycloak -o jsonpath='{.items[0].metadata.name}')
ADMIN_USER=$(kubectl get secret keycloak-admin -n "$NAMESPACE" -o jsonpath='{.data.KEYCLOAK_ADMIN}' | base64 -d)
ADMIN_PASS=$(kubectl get secret keycloak-admin -n "$NAMESPACE" -o jsonpath='{.data.KEYCLOAK_ADMIN_PASSWORD}' | base64 -d)

# 3. Apply CR
info "Applying KeycloakClient CR: $CLIENT_CR_FILE"
kubectl apply -n "$NAMESPACE" -f "$CLIENT_CR_FILE"

# 4. Wait for Operator sync
info "Waiting 15s for operator to sync..."
sleep 15

# 5. Verify in Keycloak
info "Verifying client existance via kcadm.sh..."

# Authenticate execution
EXEC_CMD="/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user $ADMIN_USER --password $ADMIN_PASS --config /tmp/kcadm.config && /opt/keycloak/bin/kcadm.sh get clients -r master -q clientId=$CLIENT_ID --config /tmp/kcadm.config"

# Disable path conversion for Windows/Git Bash
export MSYS_NO_PATHCONV=1
RESULT=$(kubectl exec -n "$NAMESPACE" "$KEYCLOAK_POD" -- sh -c "$EXEC_CMD")

if [[ "$RESULT" == *"\"clientId\" : \"$CLIENT_ID\""* ]]; then
    info "SUCCESS: Client '$CLIENT_ID' successfully created in Keycloak!"
    echo "$RESULT" | jq 'map(del(.secret))'

    info ""
    info "=== Manual Verification ==="
    info "1. Access Keycloak: http://localhost:8080"
    info "2. Login User: $ADMIN_USER"
    info "   Login Pass: (hidden) - Retrieve with:"
    info "   kubectl get secret keycloak-admin -n $NAMESPACE -o jsonpath='{.data.KEYCLOAK_ADMIN_PASSWORD}' | base64 -d"
    info "3. Go to Realm 'master' -> Clients"
    info "4. You should see '$CLIENT_ID' in the list."

    info ""
    info "=== Secret Verification ==="
    if kubectl get secret "$CLIENT_ID-secret" -n "$NAMESPACE" >/dev/null 2>&1; then
        info "SUCCESS: Secret '$CLIENT_ID-secret' created in K8s!"
        # Verify key exists but do not print value
        if kubectl get secret "$CLIENT_ID-secret" -n "$NAMESPACE" -o jsonpath='{.data.CLIENT_SECRET}' | grep -q .; then
             info "  CLIENT_SECRET: [FOUND]"
        else
             warn "  CLIENT_SECRET: [MISSING or EMPTY]"
        fi
    else
        warn "WARNING: Secret '$CLIENT_ID-secret' NOT found in Kubernetes."
    fi
else
    warn "ERROR: Client '$CLIENT_ID' NOT found in Keycloak."
    echo "Raw output: $RESULT"
    fail "Verification failed." 1
fi
