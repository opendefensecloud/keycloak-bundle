#!/bin/bash
# ==============================================================================
# deploy-instance.sh - Deploy PostgreSQL + Keycloak (without CNPG check)
# ==============================================================================
#
# PURPOSE:
#   Simplified deployment script that deploys PostgreSQL and Keycloak
#   without checking for CloudNativePG operator. Use this when you know
#   the operator is already installed.
#
# USAGE:
#   ./scripts/deploy-instance.sh [instance-name]
#
# ARGUMENTS:
#   instance-name   Optional. Name for the instance.
#                   If not provided, generates "dev-<random>" (e.g., dev-a7x2k)
#                   Creates namespace "keycloak-<instance-name>"
#
# NAMING CONVENTION:
#   - dev-<random>  : Development instances (auto-generated default)
#   - ms1, ms2, ms3 : Milestone releases
#   - poc           : Proof of concept
#   - alpha, beta   : Pre-release stages
#   - final         : Production release
#
# EXAMPLES:
#   ./scripts/deploy-instance.sh           # Deploy to keycloak-dev-<random>
#   ./scripts/deploy-instance.sh ms2       # Deploy to keycloak-ms2
#   ./scripts/deploy-instance.sh test      # Deploy to keycloak-test
#
# DIFFERENCE FROM deploy-all.sh:
#   - Does NOT check/install CloudNativePG operator
#   - Assumes operator is already present
#   - Use deploy-all.sh for first-time deployments
#
# SEE ALSO:
#   deploy-all.sh - Full deployment with operator installation
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Generate random suffix if no instance name provided
if [[ -n "$1" ]]; then
    INSTANCE_NAME="$1"
else
    INSTANCE_NAME="dev-$(generate_suffix)"
    info "No instance name provided, using: $INSTANCE_NAME"
fi
NAMESPACE="keycloak-$INSTANCE_NAME"

info "=== Deploying Keycloak Instance: $INSTANCE_NAME ==="
info "Namespace: $NAMESPACE"

# Deploy PostgreSQL
"$SCRIPT_DIR/deploy-postgres.sh" "$NAMESPACE" || fail "PostgreSQL deployment failed" 1

# Small delay for DB initialization
sleep 5

# Deploy Keycloak
"$SCRIPT_DIR/deploy-keycloak.sh" "$NAMESPACE" || fail "Keycloak deployment failed" 2

info "=== Instance $INSTANCE_NAME deployed ==="
info ""
info "To remove this instance:"
info "  ./scripts/cleanup.sh $INSTANCE_NAME"
