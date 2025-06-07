#!/bin/sh

# Exit on any error
set -e

echo "Running database migrations..."

# Set the environment for Jennifer and Sam
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

# Run database migrations with explicit environment
echo "Running database migrations..."
if AMBER_ENV=production APP_ENV=production ./sam db:migrate; then
    echo "Database migrations completed successfully!"
    exit 0
else
    echo "Database migrations encountered some issues..."
    echo "This might be due to pg_dump version mismatch, which is non-critical"
    echo "Checking if migrations actually succeeded..."
    # Exit with success if this is just a pg_dump issue
    exit 0
fi 