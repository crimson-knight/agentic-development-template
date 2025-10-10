#!/bin/sh

# Exit on any error
set -e

echo "Running database migrations..."

# Set the environment for the application
export AMBER_ENV=production
export APP_ENV=production

# Debug: Print environment variables to verify they're set
echo "Environment variables:"
echo "AMBER_ENV: $AMBER_ENV"
echo "APP_ENV: $APP_ENV"
echo "DATABASE_URL: ${DATABASE_URL:0:20}..." # Only show first 20 chars for security

# Wait a moment for the database to be fully ready
echo "Waiting for database to be ready..."
sleep 10

# Build micrate if it doesn't exist
if [ ! -f "./bin/micrate" ]; then
    echo "Building micrate..."
    crystal build db/micrate.cr -o bin/micrate
fi

# Run database migrations with micrate
echo "Running database migrations..."
if AMBER_ENV=production APP_ENV=production ./bin/micrate up; then
    echo "Database migrations completed successfully!"
    exit 0
else
    echo "Database migrations failed!"
    exit 1
fi 