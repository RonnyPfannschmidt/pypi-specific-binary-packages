#!/bin/bash
# Create GitHub release with wheel artifacts

set -e

WHEELS_DIR="${1:-release-wheels}"
RELEASE_TAG_PREFIX="${2:-release}"

echo "Creating GitHub release..."

# Check if we have wheels to release
if [ ! -d "$WHEELS_DIR" ] || [ -z "$(find "$WHEELS_DIR" -name "*.whl" 2>/dev/null)" ]; then
    echo "No wheels found in $WHEELS_DIR, skipping release creation"
    exit 0
fi

# Generate release tag based on date
RELEASE_TAG="$RELEASE_TAG_PREFIX-$(date +'%Y%m%d-%H%M%S')"

echo "Creating release with tag: $RELEASE_TAG"

# Create release notes
cat > release-notes.md << EOF
# PyPI Specific Binary Packages Release

This release contains pre-built wheels for packages that cannot be distributed as manylinux wheels:

- **gssapi**: Generic Security Service Application Program Interface
- **netifaces**: Portable network interface information
- **python-qpid-proton**: Python bindings for Apache Qpid Proton

## Built for:
- Python 3.12 and 3.13
- Linux (ubuntu-latest)
- macOS (macos-latest)

## Installation
Download the appropriate wheel for your platform and Python version, then install with:
\`\`\`
pip install <wheel-file>
\`\`\`

## Available Wheels:
EOF

# List available wheels in release notes
for wheel in "$WHEELS_DIR"/*.whl; do
    if [ -f "$wheel" ]; then
        echo "- $(basename "$wheel")" >> release-notes.md
    fi
done

cat >> release-notes.md << EOF

Generated on: $(date)
EOF

# Create the release
echo "Creating GitHub release with $(find "$WHEELS_DIR" -name "*.whl" | wc -l) wheel files..."
gh release create "$RELEASE_TAG" \
    --title "Binary Packages - $(date +'%Y-%m-%d %H:%M:%S')" \
    --notes-file release-notes.md \
    "$WHEELS_DIR"/*.whl

# Clean up
rm -f release-notes.md

echo "Release created successfully: $RELEASE_TAG"
