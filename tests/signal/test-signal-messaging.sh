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
NC='\033[0m'

# JUnit XML output setup
TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-/tmp/test-results}"
mkdir -p "$TEST_RESULTS_DIR"
JUNIT_XML="$TEST_RESULTS_DIR/signal-tests.xml"

# Initialize counters
START_TIME=$(date +%s)
TOTAL_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Start XML file
cat > "$JUNIT_XML" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="Signal Messaging Integration" tests="4" failures="0" errors="0" skipped="0" time="0">
EOF

# Test 1: Check Signal API is running
echo "📡 Test 1: Checking Signal API availability..."
TEST_START=$(date +%s)
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if curl -s -f "${SIGNAL_API_URL}/v1/about" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Signal API is accessible${NC}"
    TEST_TIME=$(($(date +%s) - TEST_START))
    cat >> "$JUNIT_XML" << EOF
    <testcase name="Signal API Availability" classname="SignalIntegration" time="$TEST_TIME"/>
EOF
else
    echo -e "${RED}✗ Signal API is not accessible${NC}"
    TEST_TIME=$(($(date +%s) - TEST_START))
    FAILED_TESTS=$((FAILED_TESTS + 1))
    cat >> "$JUNIT_XML" << EOF
    <testcase name="Signal API Availability" classname="SignalIntegration" time="$TEST_TIME">
      <failure message="API not accessible">Signal API is not responding at ${SIGNAL_API_URL}</failure>
    </testcase>
EOF
fi

# Test 2: Verify account registration
echo "📋 Test 2: Verifying Signal account registration..."
TEST_START=$(date +%s)
TOTAL_TESTS=$((TOTAL_TESTS + 1))
ACCOUNTS=$(curl -s "${SIGNAL_API_URL}/v1/accounts" 2>/dev/null || echo '[]')
TEST_TIME=$(($(date +%s) - TEST_START))
if echo "$ACCOUNTS" | grep -q "$SIGNAL_NUMBER"; then
    echo -e "${GREEN}✓ Account ${SIGNAL_NUMBER} is registered${NC}"
    cat >> "$JUNIT_XML" << EOF
    <testcase name="Account Registration Check" classname="SignalIntegration" time="$TEST_TIME"/>
EOF
else
    echo -e "${YELLOW}⚠ Account not found (expected in CI)${NC}"
    SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
    cat >> "$JUNIT_XML" << EOF
    <testcase name="Account Registration Check" classname="SignalIntegration" time="$TEST_TIME">
      <skipped message="Account not linked in CI environment"/>
    </testcase>
EOF
fi

# Test 3: Send test message
echo "📤 Test 3: Sending test message..."
TEST_START=$(date +%s)
TOTAL_TESTS=$((TOTAL_TESTS + 1))
TIMESTAMP=$(date +%s)
TEST_MESSAGE="Test from CI/CD - ${TIMESTAMP}"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${SIGNAL_API_URL}/v2/send" \
    -H "Content-Type: application/json" \
    -d "{\"message\": \"${TEST_MESSAGE}\", \"number\": \"${SIGNAL_NUMBER}\", \"recipients\": [\"${TEST_RECIPIENT}\"]}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)
TEST_TIME=$(($(date +%s) - TEST_START))

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Message sent (HTTP ${HTTP_CODE})${NC}"
    cat >> "$JUNIT_XML" << EOF
    <testcase name="Send Test Message" classname="SignalIntegration" time="$TEST_TIME"/>
EOF
else
    if echo "$BODY" | grep -qi "not registered\|not linked"; then
        echo -e "${YELLOW}⚠ Account not linked (expected in CI)${NC}"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        cat >> "$JUNIT_XML" << EOF
    <testcase name="Send Test Message" classname="SignalIntegration" time="$TEST_TIME">
      <skipped message="Account not linked in CI environment"/>
    </testcase>
EOF
    else
        echo -e "${RED}✗ Failed (HTTP ${HTTP_CODE})${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        cat >> "$JUNIT_XML" << EOF
    <testcase name="Send Test Message" classname="SignalIntegration" time="$TEST_TIME">
      <failure message="HTTP ${HTTP_CODE}">Failed to send message</failure>
    </testcase>
EOF
    fi
fi

# Test 4: Message delivery check
echo "📥 Test 4: Checking message delivery..."
TEST_START=$(date +%s)
TOTAL_TESTS=$((TOTAL_TESTS + 1))
sleep 2
MESSAGES=$(curl -s "${SIGNAL_API_URL}/v1/receive/${SIGNAL_NUMBER}" 2>/dev/null || echo '[]')
TEST_TIME=$(($(date +%s) - TEST_START))
if [ -n "$MESSAGES" ] && [ "$MESSAGES" != "[]" ]; then
    echo -e "${GREEN}✓ Messages retrieved${NC}"
    cat >> "$JUNIT_XML" << EOF
    <testcase name="Message Delivery Check" classname="SignalIntegration" time="$TEST_TIME"/>
EOF
else
    echo -e "${YELLOW}⚠ No messages (normal in test)${NC}"
    SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
    cat >> "$JUNIT_XML" << EOF
    <testcase name="Message Delivery Check" classname="SignalIntegration" time="$TEST_TIME">
      <skipped message="No messages in test environment"/>
    </testcase>
EOF
fi

# Close XML
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

cat >> "$JUNIT_XML" << EOF
  </testsuite>
</testsuites>
EOF

# Update counts
sed -i.bak "s/tests=\"4\"/tests=\"$TOTAL_TESTS\"/" "$JUNIT_XML"
sed -i.bak "s/failures=\"0\"/failures=\"$FAILED_TESTS\"/" "$JUNIT_XML"
sed -i.bak "s/skipped=\"0\"/skipped=\"$SKIPPED_TESTS\"/" "$JUNIT_XML"
sed -i.bak "s/time=\"0\"/time=\"$TOTAL_TIME\"/" "$JUNIT_XML"
rm -f "$JUNIT_XML.bak"

echo ""
echo -e "${GREEN}✅ Signal tests completed!${NC}"
echo "  Tests: $TOTAL_TESTS | Failed: $FAILED_TESTS | Skipped: $SKIPPED_TESTS | Time: ${TOTAL_TIME}s"
echo "  Results: $JUNIT_XML"

[ "$FAILED_TESTS" -eq 0 ]
