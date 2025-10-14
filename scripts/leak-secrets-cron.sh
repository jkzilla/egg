#!/bin/bash
# Cron job to leak fake secrets for TruffleHog Enterprise testing
# DO NOT USE IN PRODUCTION - FOR TESTING ONLY

set -e

REPO_DIR="/Users/johanna/src/haileysgarden/egg"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LEAK_FILE="test-data/leaked-secrets-${TIMESTAMP}.env"

cd "$REPO_DIR"

# Create test-data directory if it doesn't exist
mkdir -p test-data

# Generate fake secrets with realistic patterns
cat > "$LEAK_FILE" << EOF
# FAKE LEAKED SECRETS - TESTING TRUFFLEHOG ENTERPRISE
# Generated at: $(date)
# Leak ID: ${TIMESTAMP}

# AWS Credentials
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE${RANDOM}
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY${RANDOM}

# GitHub Token
GITHUB_TOKEN=ghp_$(openssl rand -hex 20)

# Stripe API Key
STRIPE_SECRET_KEY=sk_live_$(openssl rand -hex 24)

# SendGrid API Key
SENDGRID_API_KEY=SG.$(openssl rand -base64 22).$(openssl rand -base64 43)

# Slack Webhook
SLACK_WEBHOOK=https://hooks.slack.com/services/T$(openssl rand -hex 8)/B$(openssl rand -hex 8)/$(openssl rand -hex 12)

# Database URL
DATABASE_URL=postgresql://admin:SuperSecret${RANDOM}@db.example.com:5432/production

# JWT Secret
JWT_SECRET=jwt-secret-key-$(openssl rand -hex 32)

# Twilio Credentials
TWILIO_ACCOUNT_SID=AC$(openssl rand -hex 16)
TWILIO_AUTH_TOKEN=$(openssl rand -hex 16)

# Mailgun API Key
MAILGUN_API_KEY=key-$(openssl rand -hex 16)

# API Keys
API_KEY=$(openssl rand -hex 32)
SECRET_KEY=$(openssl rand -hex 32)

# Private Key (fake RSA format)
PRIVATE_KEY=-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA$(openssl rand -base64 64 | tr -d '\n')
$(openssl rand -base64 64 | tr -d '\n')
-----END RSA PRIVATE KEY-----
EOF

# Git operations
git add "$LEAK_FILE"
git commit --no-verify -m "TEST: Automated secret leak ${TIMESTAMP}

⚠️ INTENTIONAL LEAK FOR TRUFFLEHOG TESTING ⚠️

This is an automated test commit containing FAKE credentials
to test TruffleHog Enterprise detection and graphing.

Leak timestamp: $(date)
Leak ID: ${TIMESTAMP}

ALL CREDENTIALS ARE FAKE - FOR TESTING ONLY"

# Try to push (will be blocked by GitHub push protection)
echo "Attempting to push fake secrets..."
git push origin main 2>&1 | tee /tmp/trufflehog-push-${TIMESTAMP}.log || {
    echo "Push blocked by GitHub (expected)"
    echo "Resetting commit..."
    git reset --soft HEAD~1
    git reset HEAD "$LEAK_FILE"
    rm -f "$LEAK_FILE"
    echo "Cleaned up test leak"
}

echo "Secret leak test completed at $(date)"
EOF
chmod +x /Users/johanna/src/haileysgarden/egg/scripts/leak-secrets-cron.sh
