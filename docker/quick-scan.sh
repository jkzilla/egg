#!/bin/bash
set -e

echo "🔍 TruffleHog Quick Scan"
echo "========================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Check for GitHub token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠️  GITHUB_TOKEN not set. Reading from .env file..."
    if [ -f .env ]; then
        export $(cat .env | grep GITHUB_TOKEN | xargs)
    fi
fi

# Menu
echo "Select scan type:"
echo "1) Scan GitHub repository (jkzilla/egg)"
echo "2) Scan local filesystem"
echo "3) Scan with Docker Compose"
echo "4) Deploy to Kubernetes (minikube/kind)"
echo ""
read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        echo ""
        echo "🔎 Scanning GitHub repository..."
        docker run --rm \
            -e GITHUB_TOKEN=$GITHUB_TOKEN \
            trufflesecurity/trufflehog:latest \
            github --repo=https://github.com/jkzilla/egg \
            --json --only-verified
        ;;
    2)
        echo ""
        echo "🔎 Scanning local filesystem..."
        docker run --rm \
            -v $(pwd)/..:/scan:ro \
            trufflesecurity/trufflehog:latest \
            filesystem /scan \
            --json --only-verified
        ;;
    3)
        echo ""
        echo "🔎 Starting Docker Compose scan..."
        docker-compose -f docker-compose-trufflehog.yaml up trufflehog
        ;;
    4)
        echo ""
        echo "🔎 Deploying to Kubernetes..."
        kubectl apply -f trufflehog-deployment.yaml
        kubectl apply -f trufflehog-service.yaml
        echo ""
        echo "✅ Deployed! Check status with:"
        echo "   kubectl get pods -l app=trufflehog"
        echo "   kubectl logs -f deployment/trufflehog"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✅ Scan complete!"
