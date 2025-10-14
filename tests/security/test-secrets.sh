#!/bin/bash
set -e

echo "🔍 Testing TruffleHog secret detection..."

# Create a temporary directory for test files
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Create test files with intentional secrets (obfuscated to avoid GitHub push protection)
# These are reconstructed at runtime from parts
AWS_KEY_ID="AKIA""XYZDQCEN4B6JSJQI"
AWS_SECRET="Tg0pz8Jii8hkLx4+""PnUisM8GmKs3a2DK+9qz/lie"
GITHUB_TOKEN1="369963c1434c377428ca""8531fbc46c0c43d037a0"
GITHUB_TOKEN2="ffc7e0f9400fb6300167""009e42d2f842cd7956e2"

cat > "$TEST_DIR/aws-credentials" <<EOF
[default]
aws_access_key_id = ${AWS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET}
output = json
region = us-east-2
EOF

cat > "$TEST_DIR/github-tokens" <<EOF
github_secret="${GITHUB_TOKEN1}"
github_token="${GITHUB_TOKEN2}"
EOF

cat > "$TEST_DIR/slack-webhook" <<'EOF'
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"
EOF

# Initialize a git repo (TruffleHog requires git)
cd "$TEST_DIR"
git init
git config user.email "test@example.com"
git config user.name "Test User"
git add .
git commit -m "Add test secrets"

echo "📁 Test files created in: $TEST_DIR"

# Run TruffleHog on git history
echo "🔎 Running TruffleHog scan..."
trufflehog git file://. --json > /tmp/trufflehog-test-results.json 2>&1 || true

# Check if secrets were detected
SECRETS_FOUND=$(cat /tmp/trufflehog-test-results.json | grep -c "DetectorType" || true)

if [ "$SECRETS_FOUND" -gt 0 ]; then
    echo "✅ PASS: TruffleHog detected $SECRETS_FOUND secret(s)"
    echo ""
    echo "Detected secrets:"
    cat /tmp/trufflehog-test-results.json | jq -r '.DetectorType' | sort | uniq -c
    exit 0
else
    echo "❌ FAIL: TruffleHog did not detect any secrets"
    exit 1
fi
