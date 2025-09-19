#!/bin/bash
# Download artifacts from GitHub releases to avoid rebuilding existing versions

set -e

# Configuration
GITHUB_REPO=${GITHUB_REPO:-"RonnyPfannschmidt/pypi-specific-binary-packages"}  # GitHub repository (e.g., "owner/repo")
GITHUB_TOKEN=${GITHUB_TOKEN:-""}  # Optional GitHub token for private repos or higher rate limits
RELEASE_TAG=${RELEASE_TAG:-"latest"}  # Release tag to download from, "latest" for most recent
WHEELS_DIR="wheels"
FORCE_DOWNLOAD=${FORCE_DOWNLOAD:-false}

# Package list - should match the build script
PACKAGES_TO_BUILD=${PACKAGES_TO_BUILD:-"gssapi==1.9.0 netifaces==0.11.0 python-qpid-proton==0.40.0 gssapi netifaces python-qpid-proton"}

# Validate configuration
if [ -z "$GITHUB_REPO" ]; then
    echo "ERROR: GITHUB_REPO must be set (e.g., 'owner/repo')"
    echo "Usage: GITHUB_REPO=owner/repo $0"
    exit 1
fi

# Check for required dependencies
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required for JSON parsing but not installed"
    echo "Please install jq: sudo apt-get install jq (Ubuntu/Debian) or brew install jq (macOS)"
    exit 1
fi

echo "Downloading existing artifacts from GitHub releases..."
echo "Repository: $GITHUB_REPO"
echo "Release: $RELEASE_TAG"
echo "Target: $WHEELS_DIR"

# Create wheels directory if it doesn't exist
mkdir -p "$WHEELS_DIR"

# Set up curl headers
CURL_HEADERS=()
if [ -n "$GITHUB_TOKEN" ]; then
    CURL_HEADERS+=("-H" "Authorization: token $GITHUB_TOKEN")
fi

# Get release information
if [ "$RELEASE_TAG" = "latest" ]; then
    release_url="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
else
    release_url="https://api.github.com/repos/$GITHUB_REPO/releases/tags/$RELEASE_TAG"
fi

echo "Fetching release information..."
release_data=$(curl -s "${CURL_HEADERS[@]}" "$release_url")

if echo "$release_data" | grep -q '"message": "Not Found"'; then
    echo "ERROR: Release not found. Check repository name and release tag."
    exit 1
fi

# Extract release assets using jq for robust JSON parsing
assets=$(echo "$release_data" | jq -r '.assets[] | select(.browser_download_url | test("\\.whl$")) | .browser_download_url')

if [ -z "$assets" ]; then
    echo "No wheel assets found in release $RELEASE_TAG"
    exit 0
fi

echo "Found wheel assets in release:"
echo "$assets"

downloaded_count=0
skipped_count=0

# Convert packages to array for filtering
IFS=' ' read -ra packages <<< "$PACKAGES_TO_BUILD"

# Download each wheel asset
while IFS= read -r asset_url; do
    if [ -z "$asset_url" ]; then
        continue
    fi

    wheel_file=$(basename "$asset_url")
    target_path="$WHEELS_DIR/$wheel_file"

    # Check if this wheel matches any of our target packages AND is compatible with our platform and Python version
    package_match=false
    for package in "${packages[@]}"; do
        package_name=$(echo "$package" | sed 's/[<>=!].*//')
        wheel_name="${package_name//-/_}"

        # Extract wheel tags: name-version-pyver-abi-platform.whl
        # Example: my_package-1.0.0-py3-none-any.whl
        if [[ "$wheel_file" =~ ^${wheel_name}-.*-(py[23][0-9]?|py3|py2|py2\.py3|cp[0-9]+)-([^-]+)-([^.]+)\.whl$ ]]; then
            python_tag="${BASH_REMATCH[1]}"
            # abi_tag="${BASH_REMATCH[2]}" - not currently used in compatibility check
            platform_tag="${BASH_REMATCH[3]}"

            # Get current python version info
            current_python_major=$(python3 -c 'import sys; print(sys.version_info.major)')
            current_python_minor=$(python3 -c 'import sys; print(sys.version_info.minor)')
            current_python_tag="py${current_python_major}"
            current_cpython_tag="cp${current_python_major}${current_python_minor}"

            # Get current platform tag (simplified - covers most common cases)
            current_platform_tag=$(python3 -c 'import sysconfig; print(sysconfig.get_platform().replace("-", "_").replace(".", "_"))')

            # Check Python compatibility
            python_compatible=false
            if [[ "$python_tag" == "py2.py3" ]] || \
               [[ "$python_tag" == "py3" ]] || \
               [[ "$python_tag" == "$current_python_tag" ]] || \
               [[ "$python_tag" == "$current_cpython_tag" ]]; then
                python_compatible=true
            fi

            # Check platform compatibility (accept "any" platform or matching platform)
            platform_compatible=false
            if [[ "$platform_tag" == "any" ]] || [[ "$platform_tag" == "$current_platform_tag" ]]; then
                platform_compatible=true
            fi

            if [[ "$python_compatible" == "true" ]] && [[ "$platform_compatible" == "true" ]]; then
                package_match=true
                break
            fi
        else
            # Fallback to simple prefix matching for non-standard wheel names
            if echo "$wheel_file" | grep -q "^${wheel_name}-"; then
                echo "Warning: Using fallback matching for non-standard wheel: $wheel_file"
                package_match=true
                break
            fi
        fi
    done

    if [ "$package_match" = "false" ]; then
        echo "Skipping $wheel_file (not in target package list)"
        continue
    fi

    if [ "$FORCE_DOWNLOAD" = "true" ] || [ ! -f "$target_path" ]; then
        echo "Downloading: $wheel_file"
        if curl -L -s "${CURL_HEADERS[@]}" "$asset_url" -o "$target_path"; then
            echo "  ✓ Downloaded successfully"
            downloaded_count=$((downloaded_count + 1))
        else
            echo "  ✗ Download failed"
            rm -f "$target_path"
        fi
    else
        echo "Skipping: $wheel_file (already exists)"
        skipped_count=$((skipped_count + 1))
    fi
done <<< "$assets"

echo ""
echo "Download summary:"
echo "  Downloaded: $downloaded_count wheels"
echo "  Skipped: $skipped_count wheels (already present)"
echo ""
echo "Current wheels directory:"
ls -la "$WHEELS_DIR/" 2>/dev/null || echo "No wheels found in $WHEELS_DIR"

echo ""
echo "Usage examples:"
echo "  Basic usage:           GITHUB_REPO=owner/repo $0"
echo "  Specific release:      GITHUB_REPO=owner/repo RELEASE_TAG=v1.0.0 $0"
echo "  Force re-download:     GITHUB_REPO=owner/repo FORCE_DOWNLOAD=true $0"
echo "  With GitHub token:     GITHUB_REPO=owner/repo GITHUB_TOKEN=your_token $0"
