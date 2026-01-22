#!/bin/bash

# CI/CD Pipeline Quick Setup Script

echo "🚀 Setting up CI/CD Pipeline for Titanic API"
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Install from: https://cli.github.com/"
    exit 1
fi

echo "📝 Setting up GitHub Secrets..."
echo ""
echo "Please enter the following information:"
echo ""

read -p "Docker Hub Username: " docker_username
read -sp "Docker Hub Password/Token: " docker_password
echo ""
read -p "Postgres User: " postgres_user
read -sp "Postgres Password: " postgres_password
echo ""

# Set secrets
gh secret set DOCKER_USERNAME -b"$docker_username"
gh secret set DOCKER_PASSWORD -b"$docker_password"
gh secret set POSTGRES_USER -b"$postgres_user"
gh secret set POSTGRES_PASSWORD -b"$postgres_password"

echo ""
echo "✅ Secrets configured successfully!"
echo ""
echo "📦 Next steps:"
echo "1. Commit and push the workflow files"
echo "2. Check Actions tab in GitHub repository"
echo "3. Create a release (v1.0.0) to trigger semantic versioning"
echo ""
echo "🏷️  Create semantic version:"
echo "  git tag v1.0.0"
echo "  git push origin v1.0.0"
echo ""
echo "🔗 Useful commands:"
echo "  - View workflows: gh workflow list"
echo "  - View runs: gh run list"
echo "  - View logs: gh run view <run-id> --log"
echo ""
echo "🐳 Pull your image:"
echo "  docker pull $docker_username/titanic-api:latest"
echo ""
echo "📚 Read .github/CICD.md for detailed documentation"
