#!/bin/bash
# Local validation script for testing package builds
# This script can be used to test the build process locally before running the workflow

set -e

echo "=== Local Package Build Validation ==="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create temporary directories
mkdir -p /tmp/test-build
cd /tmp/test-build

echo "Installing build dependencies..."
# Use the shared dependency installation script
source "$SCRIPT_DIR/scripts/install-dependencies.sh"

echo "Testing package builds..."
# Use the shared build script
source "$SCRIPT_DIR/scripts/build-wheels.sh"

echo ""
echo "=== Build Results ==="
echo "Built wheels:"
ls -la wheels/ 2>/dev/null || echo "No wheels built"

echo ""
echo "Validation complete. Check the wheels/ directory for built packages."