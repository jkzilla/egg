# Security Tests

This directory contains security-related tests for the CI/CD pipeline.

## Test Cases

### test-secrets.sh

Tests that TruffleHog is properly configured and can detect common secret patterns.

**What it tests:**
- AWS credentials detection
- GitHub token detection
- Slack webhook detection
- TruffleHog is installed and working
- Configuration is correct

**How to run locally:**
```bash
cd tests/security
chmod +x test-secrets.sh
./test-secrets.sh
```

**Expected output:**
```
✅ PASS: TruffleHog detected 3 secret(s)
```

## Adding New Test Cases

To add a new security test:

1. Create a new shell script in this directory
2. Make it executable: `chmod +x your-test.sh`
3. Add it to the CircleCI config
4. Document it in this README

## Test Secrets

All secrets in test files are:
- **Fake/Invalid** - They don't work with real services
- **From public test repositories** - Like https://github.com/dustin-decker/secretsandstuff
- **Obfuscated in source** - Split into parts to avoid GitHub push protection
- **Reconstructed at runtime** - Assembled during test execution
- **Safe to commit** - They're intentionally leaked for testing purposes

### Why Obfuscation?

The test secrets are split into parts (e.g., `"AKIA" + "XYZDQCEN4B6JSJQI"`) to prevent GitHub's push protection from blocking commits. This allows us to:
1. Test that TruffleHog works correctly
2. Keep the test in version control
3. Run automated tests in CI/CD

The secrets are reassembled at runtime in a temporary directory, where TruffleHog can detect them.

## CI/CD Integration

These tests run in CircleCI as part of the `security-scan` job.

See `.circleci/config.yml` for the full configuration.
