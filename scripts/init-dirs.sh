#!/bin/bash
# ==============================================================================
# init-dirs.sh - Recreate project directory structure
# ==============================================================================
#
# PURPOSE:
#   Recreates the project directory structure from the .gitkeep-dirs file.
#   Useful after cloning when empty directories weren't preserved by Git.
#
# USAGE:
#   ./scripts/init-dirs.sh
#
# EXAMPLES:
#   ./scripts/init-dirs.sh           # Create all directories from .gitkeep-dirs
#
# PREREQUISITES:
#   - .gitkeep-dirs file must exist in project root
#   - File should contain one directory path per line
#   - Lines starting with # are treated as comments
#
# NOTES:
#   - Creates directories recursively (mkdir -p)
#   - Safe to run multiple times
#   - Typically only needed after fresh clone
#
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

if [[ -f .gitkeep-dirs ]]; then
    while IFS= read -r dir; do
        [[ "$dir" =~ ^#.*$ || -z "$dir" ]] && continue
        mkdir -p "$dir"
        info "Created: $dir"
    done < .gitkeep-dirs
else
    fail ".gitkeep-dirs not found" 1
fi

info "Done."
