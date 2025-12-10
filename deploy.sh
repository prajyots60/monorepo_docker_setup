#!/bin/bash

# Deployment Script for Monorepo Docker Application
# Usage: ./deploy.sh [dev|prod] [pull|build]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ENV=${1:-dev}
ACTION=${2:-pull}

echo -e "${GREEN}🚀 Monorepo Deployment Script${NC}"
echo "================================"
echo ""

# Function to print colored messages
print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Deploy based on environment
if [ "$ENV" = "prod" ]; then
    print_info "Deploying to PRODUCTION using DockerHub images..."
    
    if [ ! -f "docker-compose.prod.yml" ]; then
        print_error "docker-compose.prod.yml not found!"
        exit 1
    fi
    
    if [ "$ACTION" = "pull" ]; then
        print_info "Pulling latest images from DockerHub..."
        docker compose -f docker-compose.prod.yml pull
    fi
    
    print_info "Starting services..."
    docker compose -f docker-compose.prod.yml up -d
    
elif [ "$ENV" = "dev" ]; then
    print_info "Deploying to DEVELOPMENT using local build..."
    
    if [ "$ACTION" = "build" ]; then
        print_info "Building images locally..."
        docker compose up --build -d
    else
        print_info "Starting services..."
        docker compose up -d
    fi
    
else
    print_error "Invalid environment: $ENV"
    echo "Usage: $0 [dev|prod] [pull|build]"
    exit 1
fi

# Wait for services to be healthy
print_info "Waiting for services to be ready..."
sleep 5

# Check status
print_info "Checking service status..."
docker compose ps

echo ""
print_info "Deployment complete! ✅"
echo ""
echo "Services available at:"
echo "  📊 Backend API:    http://localhost:8082"
echo "  🔌 WebSocket:      ws://localhost:8081"
echo "  🌐 Next.js Web:    http://localhost:3000"
echo "  🗄️  PostgreSQL:     localhost:5432"
echo ""
echo "Useful commands:"
echo "  View logs:         docker compose logs -f"
echo "  Stop services:     docker compose down"
echo "  Restart:           docker compose restart"
echo ""
