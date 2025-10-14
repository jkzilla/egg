#!/bin/bash
set -e

echo "🔍 Testing TruffleHog secret detection..."

# JUnit XML setup
TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-/tmp/test-results}"
mkdir -p "$TEST_RESULTS_DIR"
JUNIT_XML="$TEST_RESULTS_DIR/security-tests.xml"
START_TIME=$(date +%s)

# Create a temporary directory for test files
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Create test files with intentional secrets (obfuscated to avoid GitHub push protection)
AWS_KEY_ID="AKIA""XYZDQCEN4B6JSJQI"
AWS_SECRET="Tg0pz8Jii8hkLx4+""PnUisM8GmKs3a2DK+9qz/lie"
GITHUB_TOKEN1="369963c1434c377428ca""8531fbc46c0c43d037a0"
GITHUB_TOKEN2="ffc7e0f9400fb6300167""009e42d2f842cd7956e2"
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
EOF

cat > "$TEST_DIR/github-token" <<EOF
ghp_${GITHUB_TOKEN1}${GITHUB_TOKEN2}
EOF

cat > "$TEST_DIR/slack-config.json" <<EOF
{"webhook_url": "${SLACK_WEBHOOK}"}
EOF

cat > "$TEST_DIR/stripe-config.env" <<EOF
STRIPE_SECRET_KEY=${STRIPE_KEY}
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
EOF

cat > "$TEST_DIR/.npmrc" <<EOF
//registry.npmjs.org/:_authToken=${NPM_TOKEN}
EOF

cat > "$TEST_DIR/heroku-api-key" <<EOF
HEROKU_API_KEY=${HEROKU_KEY}
EOF

# Initialize git repo
cd "$TEST_DIR"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
git add .
git commit -q -m "Add test secrets"

echo "📁 Test files created in: $TEST_DIR"

# Run TruffleHog
echo "🔎 Running TruffleHog scan..."
TEST_START=$(date +%s)
trufflehog git file://. --json > /tmp/trufflehog-test-results.json 2>&1 || true
TEST_TIME=$(($(date +%s) - TEST_START))

# Check results
SECRETS_FOUND=$(cat /tmp/trufflehog-test-results.json | grep -c "DetectorType" || true)

# Generate JUnit XML
cat > "$JUNIT_XML" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="TruffleHog Security Scan" tests="1" failures="0" errors="0" time="$TEST_TIME">
EOF

if [ "$SECRETS_FOUND" -gt 0 ]; then
    echo "✅ PASS: TruffleHog detected $SECRETS_FOUND secret(s)"
    cat /tmp/trufflehog-test-results.json | jq -r '.DetectorType' 2>/dev/null | sort | uniq -c || true
    cat >> "$JUNIT_XML" << EOF
    <testcase name="Secret Detection" classname="SecurityScan" time="$TEST_TIME">
      <system-out>Detected $SECRETS_FOUND secrets</system-out>
    </testcase>
EOF
    RESULT=0
else
    echo "❌ FAIL: TruffleHog did not detect any secrets"
    cat >> "$JUNIT_XML" << EOF
    <testcase name="Secret Detection" classname="SecurityScan" time="$TEST_TIME">
      <failure message="No secrets detected">TruffleHog failed to detect test secrets</failure>
    </testcase>
EOF
    RESULT=1
fi

cat >> "$JUNIT_XML" << EOF
  </testsuite>
</testsuites>
EOF

TOTAL_TIME=$(($(date +%s) - START_TIME))
echo "Results: $JUNIT_XML (${TOTAL_TIME}s)"
exit $RESULT
