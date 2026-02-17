#!/bin/bash
# ==============================================================================
# ocm-sign.sh - Sign and verify an OCM component archive
# ==============================================================================
#
# PURPOSE:
#   Signs an OCM component archive with an RSA keypair and verifies the
#   signature. If no keypair exists, generates one automatically.
#
# USAGE:
#   ./scripts/ocm/ocm-sign.sh [archive-path] [key-name]
#
# ARGUMENTS:
#   archive-path   Optional. Path to the component archive (default: ocm-output/component-archive)
#   key-name       Optional. Base name for the keypair files (default: ocm-key)
#
# EXAMPLES:
#   ./scripts/ocm/ocm-sign.sh                                    # Sign with defaults
#   ./scripts/ocm/ocm-sign.sh ocm-output/component-archive       # Explicit path
#   ./scripts/ocm/ocm-sign.sh ocm-output/component-archive mykey # Custom keypair name
#
# OUTPUT:
#   - <key-name>.priv  : RSA private key (generated if missing)
#   - <key-name>.pub   : RSA public key  (generated if missing)
#   - Signed component archive with signature "keycloak-ocm-sig"
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

ARCHIVE_PATH="${1:-ocm-output/component-archive}"
KEY_NAME="${2:-ocm-key}"
SIGNATURE_NAME="keycloak-ocm-sig"

# Validate archive exists
if [[ ! -d "$ARCHIVE_PATH" ]]; then
    fail "Component archive not found: $ARCHIVE_PATH (run ocm-create.sh first)"
fi

# Generate keypair if not present
if [[ ! -f "${KEY_NAME}.priv" ]]; then
    info "Generating RSA keypair: ${KEY_NAME}.priv / ${KEY_NAME}.pub"
    ocm create rsakeypair "${KEY_NAME}.priv"
else
    info "Reusing existing keypair: ${KEY_NAME}.priv"
fi

# Sign
info "Signing component archive..."
ocm sign componentversions \
    --signature "$SIGNATURE_NAME" \
    --private-key "${KEY_NAME}.priv" \
    "$ARCHIVE_PATH"

# Verify
info "Verifying signature..."
ocm verify componentversions \
    --signature "$SIGNATURE_NAME" \
    --public-key "${KEY_NAME}.pub" \
    "$ARCHIVE_PATH"

# Repackage as CTF tarball if likely in standard output structure
PARENT_DIR="$(dirname "$ARCHIVE_PATH")"
if [[ -f "$PARENT_DIR/keycloak-ocm-ctf.tar.gz" ]]; then
    info "Updating CTF tarball with signature..."
    tar -czf "$PARENT_DIR/keycloak-ocm-ctf.tar.gz" -C "$ARCHIVE_PATH" .
fi

info "Component signed and verified successfully."
info "  Signature : $SIGNATURE_NAME"
info "  Public key: ${KEY_NAME}.pub"
