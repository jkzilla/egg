#!/bin/bash

# Script to install TruffleHog for secret scanning

set -e

echo "🔍 Installing TruffleHog..."

# Detect OS
OS="$(uname -s)"

case "${OS}" in
    Linux*)
        echo "Installing for Linux..."
        curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
        ;;
    Darwin*)
        echo "Installing for macOS..."
        if command -v brew &> /dev/null; then
            brew install trufflehog
        else
            curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
        fi
        ;;
    *)
        echo "Unsupported OS: ${OS}"
        exit 1
        ;;
esac

echo "✅ TruffleHog installed successfully!"
echo ""
echo "To scan your repository, run:"
echo "  trufflehog git file://. --only-verified"
echo ""
echo "To install pre-commit hooks:"
echo "  pip install pre-commit"
echo "  pre-commit install"
