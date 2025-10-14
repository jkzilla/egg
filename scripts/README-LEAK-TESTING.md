# TruffleHog Enterprise Secret Leak Testing

## ⚠️ WARNING: FOR TESTING ONLY

This directory contains scripts to simulate secret leaks for testing TruffleHog Enterprise's detection and graphing capabilities.

**ALL SECRETS GENERATED ARE FAKE AND FOR TESTING PURPOSES ONLY.**

## Scripts

### `leak-secrets-cron.sh`
Generates and attempts to commit fake secrets to test TruffleHog detection.
- Creates realistic-looking fake credentials
- Attempts to push to GitHub (will be blocked by push protection)
- Cleans up after itself
- Logs all activity

### `setup-leak-cron.sh`
Sets up a cron job to run the leak test every 30 minutes.
- Adds cron entry
- Configures logging
- Provides instructions for removal

## Setup

1. **Install the cron job:**
   ```bash
   ./scripts/setup-leak-cron.sh
   ```

2. **Verify cron job is running:**
   ```bash
   crontab -l | grep leak-secrets
   ```

3. **Monitor logs:**
   ```bash
   tail -f ~/trufflehog-leak-tests.log
   ```

## What Gets Tested

Each leak attempt includes:
- AWS Access Keys
- GitHub Personal Access Tokens
- Stripe API Keys
- SendGrid API Keys
- Slack Webhooks
- Database Connection Strings
- JWT Secrets
- Twilio Credentials
- Mailgun API Keys
- RSA Private Keys

## Expected Behavior

1. **GitHub Push Protection**: Should block the push immediately
2. **TruffleHog Enterprise**: Should detect secrets in the commit
3. **Graphing**: TruffleHog Enterprise dashboard should show:
   - Number of secrets detected over time
   - Types of secrets found
   - Trends and patterns
   - Blocked attempts

## Cleanup

### Remove the cron job:
```bash
crontab -l | grep -v 'leak-secrets-cron.sh' | crontab -
```

### Remove test files:
```bash
rm -rf test-data/leaked-secrets-*.env
```

### Clear logs:
```bash
rm ~/trufflehog-leak-tests.log
```

## Testing Manually

Run a single test without cron:
```bash
./scripts/leak-secrets-cron.sh
```

## Security Notes

- All secrets are randomly generated and FAKE
- GitHub push protection will block all pushes
- No real credentials are ever committed
- Scripts clean up after themselves
- Logs are stored locally only

## TruffleHog Enterprise Dashboard

After running for a few hours, check your TruffleHog Enterprise dashboard for:
- Secret detection graphs
- Leak attempt timeline
- Secret type distribution
- Blocked push statistics
