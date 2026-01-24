#!/bin/bash
# Helper script to get application URLs after deployment

cd "$(dirname "$0")"

echo "🔍 Checking for deployed services..."
echo ""

# Run terraform with check_services=true
terraform apply -var='check_services=true' -auto-approve > /dev/null 2>&1

# Get the URLs
VOTE_URL=$(terraform output -raw vote_app_url 2>/dev/null)
RESULT_URL=$(terraform output -raw result_app_url 2>/dev/null)

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Voting App Application URLs                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "🗳️  Vote App:   $VOTE_URL"
echo "📊 Result App: $RESULT_URL"
echo ""

# Check if URLs are actual IPs
if [[ $VOTE_URL =~ ^http://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "✅ Services are deployed and accessible!"
    echo ""
    echo "Try them now:"
    echo "  open $VOTE_URL"
    echo "  open $RESULT_URL"
elif [[ $VOTE_URL == *"<pending>"* ]]; then
    echo "⏳ LoadBalancers are being provisioned..."
    echo "   This usually takes 2-5 minutes."
    echo "   Run this script again in a minute."
elif [[ $VOTE_URL == *"Not checked"* ]]; then
    echo "ℹ️  Services haven't been deployed yet."
    echo "   Deploy via GitHub Actions first."
else
    echo "ℹ️  $VOTE_URL"
    echo "   Deploy your application via GitHub Actions,"
    echo "   then run this script again."
fi
echo ""
