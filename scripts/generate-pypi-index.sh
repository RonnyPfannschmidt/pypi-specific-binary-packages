#!/bin/bash
# Generate PyPI index using dumb-pypi tool

set -e

WHEELS_DIR="${1:-combined-wheels}"
SITE_DIR="${2:-site}"
PACKAGES_URL="${3:-wheels/}"

echo "Generating PyPI index using dumb-pypi..."

# Install dumb-pypi if not available
if ! command -v dumb-pypi >/dev/null 2>&1; then
    echo "Installing dumb-pypi..."
    pip install dumb-pypi
fi

# Create package list from wheel files
PACKAGE_LIST_FILE="package-list.txt"
if [ -d "$WHEELS_DIR" ]; then
    find "$WHEELS_DIR" -name "*.whl" -exec basename {} \; > "$PACKAGE_LIST_FILE"
    echo "Found $(wc -l < "$PACKAGE_LIST_FILE") wheel files"
else
    echo "WARNING: Wheels directory $WHEELS_DIR not found, creating empty package list"
    touch "$PACKAGE_LIST_FILE"
fi

# Generate the index using dumb-pypi
echo "Generating PyPI index..."
dumb-pypi \
    --package-list "$PACKAGE_LIST_FILE" \
    --packages-url "$PACKAGES_URL" \
    --output-dir "$SITE_DIR" \
    --title "PyPI Specific Binary Packages" \
    --no-generate-timestamp

# Copy wheels to site directory
echo "Copying wheels to site directory..."
mkdir -p "$SITE_DIR/wheels"
if [ -d "$WHEELS_DIR" ]; then
    cp "$WHEELS_DIR"/*.whl "$SITE_DIR/wheels/" 2>/dev/null || echo "No wheel files to copy"
fi

# Clean up temporary files
rm -f "$PACKAGE_LIST_FILE"

echo "PyPI index generated successfully in $SITE_DIR"
echo "Available at simple index: $SITE_DIR/simple/"