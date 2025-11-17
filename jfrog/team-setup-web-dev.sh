#!/bin/bash
# Web Development Team - npm configuration
# Run this on each web developer's machine

JFROG_URL="https://trialghxmjl.jfrog.io"
REGISTRY_URL="${JFROG_URL}/artifactory/api/npm/npm/"

echo "🌐 Configuring npm for Web Development Team..."
echo ""

# Set the registry to the virtual repository
npm config set registry "${REGISTRY_URL}"

echo "✅ Registry configured: ${REGISTRY_URL}"
echo ""
echo "🔑 Next: Authenticate with JFrog"
echo ""
echo "Option 1 - Access Token (Recommended):"
echo "  1. Go to ${JFROG_URL}/ui/admin/artifactory/user_profile"
echo "  2. Generate an access token"
echo "  3. Run: npm set //'trialghxmjl.jfrog.io'/artifactory/api/npm/npm/:_authToken=<YOUR_TOKEN>"
echo ""
echo "Option 2 - npm login:"
echo "  npm login --registry=${REGISTRY_URL}"
echo ""
echo "📦 Publishing packages:"
echo "  - Use scope: @web-dev/* for team-private packages"
echo "  - Use scope: @shared/* for packages shared with iOS team"
echo ""
echo "Example package.json:"
cat << 'EOF'
{
  "name": "@web-dev/my-component",
  "version": "1.0.0",
  "publishConfig": {
    "registry": "https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/"
  }
}
EOF
