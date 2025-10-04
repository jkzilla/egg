#!/bin/bash

# Script to validate CircleCI configuration

set -e

echo "🔍 Validating CircleCI configuration..."

# Check if circleci CLI is installed
if ! command -v circleci &> /dev/null; then
    echo "❌ CircleCI CLI not found"
    echo ""
    echo "Install it with:"
    echo "  macOS: brew install circleci"
    echo "  Linux: curl -fLSs https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/master/install.sh | bash"
    echo ""
    exit 1
fi

# Validate config
echo "Validating .circleci/config.yml..."
circleci config validate

echo ""
echo "✅ CircleCI configuration is valid!"
echo ""
echo "To test a job locally, run:"
echo "  circleci local execute --job <job-name>"
echo ""
echo "Available jobs:"
echo "  - security-scan"
echo "  - backend-build-test"
echo "  - frontend-build-test"
echo "  - integration-test"
echo "  - docker-build"
