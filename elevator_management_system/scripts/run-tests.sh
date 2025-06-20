#!/bin/bash

# Script to run tests for all services

SERVICES=("gateway" "auth_service" "dashboard_service" "elevator_service" "maintenance_service" "monitoring_service")

echo "Running tests for all services..."

for service in "${SERVICES[@]}"; do
    echo "Running tests for $service"
    cd $service
    source venv/bin/activate
    pytest tests/ -v --cov=app --cov-report=html
    cd ..
done

echo "All tests completed!"
