#!/bin/bash
# Local validation script for testing package builds
# This script can be used to test the build process locally before running the workflow

set -e

echo "=== Local Package Build Validation ==="

# Create temporary directories
mkdir -p /tmp/test-build/{tarballs,wheels}
cd /tmp/test-build

# Packages to test
packages=("gssapi" "netifaces" "python-qpid-proton")

echo "Installing build dependencies..."
pip install pip setuptools wheel build Cython -U

echo "Testing package builds..."

for package in "${packages[@]}"
do
    echo ""
    echo "--- Testing $package ---"
    
    # Download source
    echo "Downloading $package source..."
    pip download --no-deps --no-binary :all: "$package" -d tarballs
    
    # Extract
    package_path="${package//-/_}"
    tarball=$(find tarballs -name "${package_path}*.tar.gz" | head -1)
    
    if [ -z "$tarball" ]; then
        echo "ERROR: Could not find tarball for $package"
        continue
    fi
    
    echo "Extracting $tarball..."
    tar -xzf "$tarball" -C tarballs
    
    # Build
    build_dir=$(find tarballs -maxdepth 1 -type d -name "${package_path}-*" | head -1)
    
    if [ -z "$build_dir" ]; then
        echo "ERROR: Could not find build directory for $package"
        continue
    fi
    
    echo "Building wheel in $build_dir..."
    cd "$build_dir"
    
    if python -m build -w; then
        echo "SUCCESS: Built wheel for $package"
        mv dist/*.whl ../../wheels/
    else
        echo "ERROR: Failed to build wheel for $package"
    fi
    
    cd /tmp/test-build
done

echo ""
echo "=== Build Results ==="
echo "Built wheels:"
ls -la wheels/ 2>/dev/null || echo "No wheels built"

echo ""
echo "Validation complete. Check the wheels/ directory for built packages."