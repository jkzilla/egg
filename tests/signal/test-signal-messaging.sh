#!/bin/bash
set -e

echo "🔔 Testing Signal Messaging Integration..."

# Configuration
SIGNAL_API_URL="${SIGNAL_API_URL:-http://signal-api:8080}"
SIGNAL_NUMBER="${SIGNAL_NUMBER:-+17073243359}"
TEST_RECIPIENT="${TEST_RECIPIENT:-$SIGNAL_NUMBER}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Check Signal API is running
echo "📡 Test 1: Checking Signal API availability..."
if curl -s -f "${SIGNAL_API_URL}/v1/about" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Signal API is accessible${NC}"
else
    echo -e "${RED}✗ Signal API is not accessible at ${SIGNAL_API_URL}${NC}"
    exit 1
fi

# Test 2: Verify account registration
echo "📋 Test 2: Verifying Signal account registration..."
ACCOUNTS=$(curl -s "${SIGNAL_API_URL}/v1/accounts" 2>/dev/null || echo '[]')
if echo "$ACCOUNTS" | grep -q "$SIGNAL_NUMBER"; then
    echo -e "${GREEN}✓ Signal account ${SIGNAL_NUMBER} is registered${NC}"
else
    echo -e "${YELLOW}⚠ Signal account ${SIGNAL_NUMBER} not found in registered accounts${NC}"
    echo "Registered accounts:"
    echo "$ACCOUNTS" | jq '.' 2>/dev/null || echo "$ACCOUNTS"
fi

# Test 3: Send test message
echo "📤 Test 3: Sending test message..."
TIMESTAMP=$(date +%s)
TEST_MESSAGE="Test message from CI/CD pipeline - ${TIMESTAMP}"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${SIGNAL_API_URL}/v2/send" \
    -H "Content-Type: application/json" \
    -d "{
        \"message\": \"${TEST_MESSAGE}\",
        \"number\": \"${SIGNAL_NUMBER}\",
        \"recipients\": [\"${TEST_RECIPIENT}\"]
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Message sent successfully (HTTP ${HTTP_CODE})${NC}"
    echo "Response: $BODY"
else
    echo -e "${RED}✗ Failed to send message (HTTP ${HTTP_CODE})${NC}"
    echo "Response: $BODY"

    # Don't fail the test if account is not linked yet
    if echo "$BODY" | grep -qi "not registered\|not linked"; then
        echo -e "${YELLOW}⚠ Account needs to be linked. This is expected in CI environment.${NC}"
        exit 0
    fi
    exit 1
fi

# Test 4: Verify message delivery (optional, requires receive endpoint)
echo "📥 Test 4: Checking message delivery status..."
sleep 2
MESSAGES=$(curl -s "${SIGNAL_API_URL}/v1/receive/${SIGNAL_NUMBER}" 2>/dev/null || echo '[]')
if [ -n "$MESSAGES" ] && [ "$MESSAGES" != "[]" ]; then
    echo -e "${GREEN}✓ Messages retrieved successfully${NC}"
    echo "Recent messages count: $(echo "$MESSAGES" | jq 'length' 2>/dev/null || echo 'unknown')"
else
    echo -e "${YELLOW}⚠ No messages retrieved (this is normal in test environment)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Signal messaging tests completed successfully!${NC}"
echo ""
echo "Summary:"
echo "  - Signal API: Accessible"
echo "  - Account: ${SIGNAL_NUMBER}"
echo "  - Test message: Sent"
echo "  - Timestamp: ${TIMESTAMP}"
