#!/bin/bash

# Start all services
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
for i in {1..15}; do echo -n "..."; sleep 1; done
echo ""
echo "Running tests"

# Run tests for each database
for db in postgres trino; do
    echo "================================================"
    echo "Running tests for $db..."
    echo "================================================"
    dbt deps --quiet
    dbt build --target $db --quiet --full-refresh
done

# Stop all services
docker-compose down
