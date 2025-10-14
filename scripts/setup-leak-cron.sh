#!/bin/bash
# Setup cron job to leak fake secrets every 30 minutes

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LEAK_SCRIPT="$SCRIPT_DIR/leak-secrets-cron.sh"
LOG_FILE="$HOME/trufflehog-leak-tests.log"

# Make sure the leak script is executable
chmod +x "$LEAK_SCRIPT"

# Create cron job entry
CRON_JOB="*/30 * * * * $LEAK_SCRIPT >> $LOG_FILE 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "leak-secrets-cron.sh"; then
    echo "⚠️  Cron job already exists"
    echo "Current crontab:"
    crontab -l | grep "leak-secrets-cron.sh"
else
    # Add cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ Cron job added successfully!"
    echo ""
    echo "Schedule: Every 30 minutes"
    echo "Script: $LEAK_SCRIPT"
    echo "Log: $LOG_FILE"
    echo ""
    echo "Current crontab:"
    crontab -l | grep "leak-secrets-cron.sh"
fi

echo ""
echo "To remove the cron job, run:"
echo "  crontab -l | grep -v 'leak-secrets-cron.sh' | crontab -"
echo ""
echo "To view logs:"
echo "  tail -f $LOG_FILE"
EOF
chmod +x /Users/johanna/src/haileysgarden/egg/scripts/setup-leak-cron.sh
