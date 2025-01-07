#!/bin/bash
set -e

echo "🧪 Running DockerHub Distribution E2E Tests..."

# Setup
TEST_DIR=$(mktemp -d)
cd $TEST_DIR

# Create projects directory
mkdir -p projects

# Download docker-compose.yml and modify for test environment
curl -O https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/distributions/dockerhub/docker-compose.yml

# Remove any potential .gitconfig mount that might be in the downloaded file
sed -i '/\.gitconfig/d' docker-compose.yml

# Replace relative path with absolute path
sed -i "s|../../projects|$TEST_DIR/projects|g" docker-compose.yml

# Test Container Startup
echo "📦 Testing container startup..."
docker compose up -d
sleep 10

# Test Development Tools
echo "🛠️ Verifying development tools..."
docker exec dev-environment bash -c '
    echo "Node.js: $(node --version)" &&
    echo "Go: $(go version)" &&
    echo "Rust: $(cargo --version)" &&
    echo "Git: $(git --version)"
'

# Test Project Initialization
echo "📁 Testing project initialization..."
docker exec dev-environment bash -c '
    cd /usr/src/projects &&
    /usr/src/startup/init-project.sh test-project full-stack &&
    test -d test-project
'

# Cleanup
echo "🧹 Cleaning up..."
docker compose down
docker rmi cmoe640/dev-environment:latest

echo "✅ DockerHub E2E tests completed successfully" 