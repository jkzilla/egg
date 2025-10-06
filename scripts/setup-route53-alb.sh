#!/bin/bash
set -e

# Configuration
DOMAIN="haileysgarden.com"
ALB_DNS="haileys-garden-alb-855092200.us-east-1.elb.amazonaws.com"
ALB_HOSTED_ZONE="Z35SXDOTRQ7X7K"  # us-east-1 ALB hosted zone ID

echo "🌐 Setting up Route 53 DNS for $DOMAIN to point to ALB..."

# Get hosted zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
    --dns-name $DOMAIN \
    --query "HostedZones[0].Id" \
    --output text | cut -d'/' -f3)

echo "✅ Found hosted zone: $HOSTED_ZONE_ID"

# Create ALIAS records for root domain and www
echo "📝 Creating ALIAS records for $DOMAIN → $ALB_DNS"

# First, delete any existing A records
echo "🗑️  Removing any existing A records..."
EXISTING_A=$(aws route53 list-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --query "ResourceRecordSets[?Name=='$DOMAIN.' && Type=='A']" \
    --output json)

if [ "$EXISTING_A" != "[]" ]; then
    TTL=$(echo $EXISTING_A | jq -r '.[0].TTL')
    VALUE=$(echo $EXISTING_A | jq -r '.[0].ResourceRecords[0].Value')
    
    cat > /tmp/delete-a.json <<EOF
{
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet": {
        "Name": "$DOMAIN",
        "Type": "A",
        "TTL": $TTL,
        "ResourceRecords": [{"Value": "$VALUE"}]
      }
    }
  ]
}
EOF
    aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --change-batch file:///tmp/delete-a.json
    echo "✅ Deleted existing A record"
    sleep 2
fi

# Delete www A record if exists
EXISTING_WWW_A=$(aws route53 list-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --query "ResourceRecordSets[?Name=='www.$DOMAIN.' && Type=='A']" \
    --output json)

if [ "$EXISTING_WWW_A" != "[]" ]; then
    TTL=$(echo $EXISTING_WWW_A | jq -r '.[0].TTL')
    VALUE=$(echo $EXISTING_WWW_A | jq -r '.[0].ResourceRecords[0].Value')
    
    cat > /tmp/delete-www-a.json <<EOF
{
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet": {
        "Name": "www.$DOMAIN",
        "Type": "A",
        "TTL": $TTL,
        "ResourceRecords": [{"Value": "$VALUE"}]
      }
    }
  ]
}
EOF
    aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --change-batch file:///tmp/delete-www-a.json
    echo "✅ Deleted existing www A record"
    sleep 2
fi

# Create ALIAS records
cat > /tmp/route53-alias.json <<EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$DOMAIN",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "$ALB_HOSTED_ZONE",
          "DNSName": "$ALB_DNS",
          "EvaluateTargetHealth": true
        }
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "www.$DOMAIN",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "$ALB_HOSTED_ZONE",
          "DNSName": "$ALB_DNS",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}
EOF

# Apply changes
aws route53 change-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --change-batch file:///tmp/route53-alias.json

echo ""
echo "✅ DNS ALIAS Records Created!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Domain:           $DOMAIN"
echo "WWW Domain:       www.$DOMAIN"
echo "Points to:        $ALB_DNS (ALIAS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⏳ DNS propagation may take 5-60 minutes"
echo ""
echo "🧪 Test DNS resolution:"
echo "   dig $DOMAIN"
echo "   dig www.$DOMAIN"
echo ""
echo "🌐 Access your site at:"
echo "   https://$DOMAIN"
echo "   https://www.$DOMAIN"
echo ""
echo "🔒 HTTPS is enabled with your ACM certificate!"

# Clean up
rm -f /tmp/route53-alias.json /tmp/delete-a.json /tmp/delete-www-a.json
