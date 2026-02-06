#!/bin/bash
# ==============================================================================
# ocm-create.sh - Create OCM component archive for air-gapped deployment
# ==============================================================================
#
# PURPOSE:
#   Creates an Open Component Model (OCM) component archive that bundles
#   all container images and manifests needed for air-gapped deployment.
#   The archive can be transferred to disconnected environments.
#
# USAGE:
#   ./scripts/ocm-create.sh [output-directory]
#
# ARGUMENTS:
#   output-directory   Optional. Where to create the archive
#                      (default: ./ocm-output)
#
# EXAMPLES:
#   ./scripts/ocm-create.sh                    # Create in ./ocm-output
#   ./scripts/ocm-create.sh /tmp/ocm-bundle    # Custom location
#
# PREREQUISITES:
#   - OCM CLI must be installed (https://ocm.software)
#   - Network access to pull container images
#
# BUNDLES:
#   See ocm/component-descriptor.yaml for list of bundled images and resources.
#
# TRANSFER TO AIR-GAPPED:
#   Use scripts/ocm-transfer.sh
#
# SEE ALSO:
#   ocm/component-descriptor.yaml - Component metadata
#   https://ocm.software          - OCM documentation
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${1:-$PROJECT_ROOT/ocm-output}"
# Component name and version are defined in ocm/component-descriptor.yaml

# Check for ocm CLI
if ! command -v ocm &>/dev/null; then
    fail "OCM CLI not found. Install from: https://ocm.software" 1
fi

info "Creating OCM component archive..."
info "Output: $OUTPUT_DIR"

mkdir -p "$OUTPUT_DIR"

cd "$PROJECT_ROOT"

# WORKAROUND: Create manual tarball to avoid OCM CLI file locking issues on Windows
# The OCM CLI fails to cleanup temp files when internal compression is used on Windows.
info "Creating manifests.tar (workaround for Windows)..."
tar -cf manifests.tar -C manifests . || fail "Failed to create manifests.tar" 8

# CLEANUP: Remove existing archive to prevent appending to old components
if [[ -d "$OUTPUT_DIR/component-archive" ]]; then
    info "Removing old component archive..."
    rm -rf "$OUTPUT_DIR/component-archive"
fi

# Create component archive using declarative descriptor
info "Adding component version from descriptor..."
ocm add componentversions --create --file "$OUTPUT_DIR/component-archive" "ocm/component-descriptor.yaml" \
    || fail "Failed to create component archive from descriptor" 2

# Cleanup manual tarball
rm manifests.tar

# Note: Resources are now defined in ocm/component-descriptor.yaml
# We no longer need manual 'ocm add resources' calls here.

info "Creating demo tarball..."
tar -czf "$OUTPUT_DIR/keycloak-demo.tgz" -C "$OUTPUT_DIR" component-archive \
    || fail "Failed to create demo tarball" 9

info "=== OCM component archive created ==="
info "Location: $OUTPUT_DIR/component-archive"
info "Demo TGZ: $OUTPUT_DIR/keycloak-demo.tgz"
info ""
info "To transfer to air-gapped registry:"
info "  ./scripts/ocm-transfer.sh $OUTPUT_DIR/component-archive"
