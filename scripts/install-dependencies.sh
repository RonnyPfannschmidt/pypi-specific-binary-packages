#!/bin/bash
# Install system and Python dependencies for building packages

set -e

echo "Installing system dependencies..."
if [ "$1" == "ubuntu-latest" ] || [ "$(uname)" == "Linux" ]; then
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y python3-dev libkrb5-dev \
          build-essential cmake libsasl2-dev
    fi
elif [ "$1" == "macos-latest" ] || [ "$(uname)" == "Darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
        brew reinstall krb5
        brew install cmake cyrus-sasl
    fi
fi

echo "Installing Python dependencies..."
pip install pip setuptools wheel build Cython -U

echo "Dependencies installed successfully."
