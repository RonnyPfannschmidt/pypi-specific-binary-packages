#!/bin/bash
# Build wheels for specified packages

set -e

# Package list - can be overridden by environment variable
PACKAGES_TO_BUILD=${PACKAGES_TO_BUILD:-"gssapi netifaces python-qpid-proton"}

# Convert to array
IFS=' ' read -ra packages <<< "$PACKAGES_TO_BUILD"

echo "Building wheels for packages: ${packages[*]}"

# Create directories
mkdir -p tarballs
mkdir -p wheels

# Loop through each package
for package in "${packages[@]}"
do
    echo "Building $package..."
    
    # Download the package without dependencies
    pip download --no-deps --no-binary :all: "$package" -d tarballs
    
    # Extract the downloaded tar.gz file
    package_path="${package//-/_}"
    
    # Find the tarball (handle case where multiple versions might exist)
    tarball=$(find tarballs -name "${package_path}*.tar.gz" | head -1)
    
    if [ -z "$tarball" ]; then
        echo "ERROR: Could not find tarball for $package"
        continue
    fi
    
    echo "Extracting $tarball..."
    tar -xvf "$tarball" -C tarballs
    
    # Find the extracted directory
    build_dir=$(find tarballs -maxdepth 1 -type d -name "${package_path}-*" | head -1)
    
    if [ -z "$build_dir" ]; then
        echo "ERROR: Could not find build directory for $package"
        continue
    fi
    
    # Build the wheel
    echo "Building wheel in $build_dir..."
    cd "$build_dir"
    
    if python -m build -w; then
        echo "SUCCESS: Built wheel for $package"
        # Move the wheel to the wheels directory
        mv dist/*.whl ../../wheels/
    else
        echo "ERROR: Failed to build wheel for $package"
    fi
    
    # Return to original directory
    cd - > /dev/null
    
    echo "Finished building $package"
done

echo "Built wheels:"
ls -la wheels/ 2>/dev/null || echo "No wheels found"