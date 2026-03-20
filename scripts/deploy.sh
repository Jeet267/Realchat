#!/bin/bash
# Idempotent Deployment Script

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting Deployment..."

# Idempotent directory creation
mkdir -p /var/www/realchat
mkdir -p /var/log/realchat

# Install Backend Dependencies
echo "Installing backend dependencies..."
cd backend
npm install
# Restart or Start PM2 process idempotently
# Doing pm2 restart will fail if it doesn't exist, so this is handled by || pm2 start
pm2 restart realchat-backend || pm2 start src/server.js --name realchat-backend
cd ..

# Install Frontend Dependencies & Build
echo "Installing frontend dependencies..."
cd frontend
npm install
npm run build
cd ..

echo "Deployment completed successfully!"
