# pypi-specific-binary-packages

Small PyPI generator for packages that can't be manylinux - not official

## Overview

This repository automatically builds binary wheels for Python packages that cannot be distributed as manylinux wheels. The built wheels are made available through GitHub Releases and GitHub Pages.

## Supported Packages

- **gssapi**: Generic Security Service Application Program Interface
- **netifaces**: Portable network interface information
- **python-qpid-proton**: Python bindings for Apache Qpid Proton

## Build Matrix

The workflow builds wheels for:
- **Python versions**: 3.12, 3.13
- **Platforms**: Linux (ubuntu-latest), macOS (macos-latest)

## Workflow

The build process is automated via GitHub Actions and includes:

1. **Matrix builds**: Parallel building across all Python versions and platforms
2. **Artifact combination**: All wheels are collected into a single artifact
3. **GitHub Pages**: Index page with download links
4. **GitHub Releases**: Tagged releases with all wheels attached

## Installation

Download the appropriate wheel for your platform and Python version from the [Releases page](../../releases), then install with:

```bash
pip install <wheel-file>
```

Or browse available wheels at the [GitHub Pages site](https://ronnypfannschmidt.github.io/pypi-specific-binary-packages/).

## Automation

The workflow runs:
- On pushes to main/master branches
- On pull requests
- Weekly (Mondays at 6 AM UTC) to catch new package releases
- Manually via workflow dispatch
