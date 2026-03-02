#!/bin/bash
# ==============================================================================
# ocm-validate.sh - Validate an OCM component archive
# ==============================================================================
#
# PURPOSE:
#   Inspects and validates an OCM component archive by listing component
#   versions and resources. Optionally runs a full describe (requires
#   registry/OCI access).
#
# USAGE:
#   ./scripts/ocm/ocm-validate.sh [archive-path] [--full]
#
# ARGUMENTS:
#   archive-path   Optional. Path to the component archive (default: ocm-output/component-archive)
#   --full         Optional. Also run 'ocm describe' (requires OCI registry access)
#
# EXAMPLES:
#   ./scripts/ocm/ocm-validate.sh                          # Basic validation
#   ./scripts/ocm/ocm-validate.sh --full                   # With full describe
#   ./scripts/ocm/ocm-validate.sh gen/ctf                  # Custom archive path
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

ARCHIVE_PATH="ocm-output/component-archive"
FULL_DESCRIBE=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --full) FULL_DESCRIBE=true ;;
        *)      ARCHIVE_PATH="$arg" ;;
    esac
done

# Validate archive exists
if [[ ! -d "$ARCHIVE_PATH" ]]; then
    fail "Component archive not found: $ARCHIVE_PATH (run ocm-create.sh first)"
fi

info "Validating component archive: $ARCHIVE_PATH"

echo ""
echo "=== Component Versions ==="
ocm get componentversions "$ARCHIVE_PATH"

echo ""
echo "=== Resources ==="
ocm get resources "$ARCHIVE_PATH"

if [[ "$FULL_DESCRIBE" == "true" ]]; then
    echo ""
    echo "=== Full Component Descriptor ==="
    ocm describe component "$ARCHIVE_PATH"
fi

info "Validation complete."
