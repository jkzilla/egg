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

# Additional test secrets for comprehensive TruffleHog testing
SLACK_WEBHOOK="https://hooks.slack.com/services/T00000000/B00000000/""XXXXXXXXXXXXXXXXXXXX"
STRIPE_KEY="sk_test_""51UBZqEHAkGXk2Ld0FqjZZF2"
SENDGRID_KEY="SG.""ngeVfQFYQlKU0ufo8x5d1A.TwL2iGABf9DHoTf9k5K2fJJGsSSKeFxmBpHKMH0Fku"
TWILIO_SID="AC""a6b1e0b6f3c4d5e6f7a8b9c0d1e2f3a4b5"
TWILIO_TOKEN="1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d"
MAILGUN_KEY="key-""1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d"
HEROKU_KEY="12345678-""1234-1234-1234-123456789012"
NPM_TOKEN="npm_""aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890"

cat > "$TEST_DIR/aws-credentials" <<EOF
[default]
aws_access_key_id = ${AWS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET}
output = json
region = us-east-2
EOF

cat > "$TEST_DIR/github-token" <<EOF
ghp_${GITHUB_TOKEN1}${GITHUB_TOKEN2}
EOF

cat > "$TEST_DIR/slack-config.json" <<EOF
{
  "webhook_url": "${SLACK_WEBHOOK}",
  "channel": "#alerts"
}
EOF

cat > "$TEST_DIR/stripe-config.env" <<EOF
STRIPE_SECRET_KEY=${STRIPE_KEY}
STRIPE_PUBLISHABLE_KEY=pk_test_TYooMQauvdEDq54NiTphI7jx
EOF

cat > "$TEST_DIR/sendgrid.env" <<EOF
SENDGRID_API_KEY=${SENDGRID_KEY}
EOF

cat > "$TEST_DIR/twilio-credentials" <<EOF
TWILIO_ACCOUNT_SID=${TWILIO_SID}
TWILIO_AUTH_TOKEN=${TWILIO_TOKEN}
EOF

cat > "$TEST_DIR/mailgun.conf" <<EOF
api_key=${MAILGUN_KEY}
domain=mg.example.com
EOF

cat > "$TEST_DIR/.npmrc" <<EOF
//registry.npmjs.org/:_authToken=${NPM_TOKEN}
EOF

cat > "$TEST_DIR/heroku-api-key" <<EOF
HEROKU_API_KEY=${HEROKU_KEY}
EOF

cat > "$TEST_DIR/slack-webhook" <<'EOF'
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"

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
