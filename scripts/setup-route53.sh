#!/bin/bash
set -e

# Configuration
DOMAIN="haileysgarden.com"
EC2_IP="34.228.195.182"  # Your EC2 instance IP

echo "🌐 Setting up Route 53 DNS for $DOMAIN..."

# Get hosted zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
    --dns-name $DOMAIN \
    --query "HostedZones[0].Id" \
    --output text | cut -d'/' -f3)

echo "✅ Found hosted zone: $HOSTED_ZONE_ID"

# Create A record for root domain
echo "📝 Creating A record for $DOMAIN → $EC2_IP"

# First, try to delete any existing CNAME for www
echo "🗑️  Removing any existing CNAME records..."
aws route53 list-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --query "ResourceRecordSets[?Name=='www.$DOMAIN.' && Type=='CNAME']" \
    --output json > /tmp/existing-cname.json

if [ -s /tmp/existing-cname.json ] && [ "$(cat /tmp/existing-cname.json)" != "[]" ]; then
    CNAME_VALUE=$(cat /tmp/existing-cname.json | jq -r '.[0].ResourceRecords[0].Value')
    CNAME_TTL=$(cat /tmp/existing-cname.json | jq -r '.[0].TTL')

    cat > /tmp/delete-cname.json <<EOF
{
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet": {
        "Name": "www.$DOMAIN",
        "Type": "CNAME",
        "TTL": $CNAME_TTL,
        "ResourceRecords": [{"Value": "$CNAME_VALUE"}]
      }
    }
  ]
}
EOF
    aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --change-batch file:///tmp/delete-cname.json
    echo "✅ Deleted existing CNAME record"
    sleep 2
fi

cat > /tmp/route53-change.json <<EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$DOMAIN",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$EC2_IP"
          }
        ]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "www.$DOMAIN",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$EC2_IP"
          }
        ]
      }
    }
  ]
}
EOF

# Apply changes
aws route53 change-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --change-batch file:///tmp/route53-change.json

echo ""
echo "✅ DNS Records Created!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Domain:           $DOMAIN"
echo "WWW Domain:       www.$DOMAIN"
echo "Points to:        $EC2_IP"
echo "TTL:              300 seconds (5 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⏳ DNS propagation may take 5-60 minutes"
echo ""
echo "🧪 Test DNS resolution:"
echo "   dig $DOMAIN"
echo "   dig www.$DOMAIN"
echo ""
echo "🌐 Once propagated, access your site at:"
echo "   http://$DOMAIN"
echo "   http://www.$DOMAIN"

# Clean up
rm /tmp/route53-change.json
