#!/bin/bash

# Development setup script

echo "Setting up development environment..."

# Create virtual environment for each service
SERVICES=("gateway" "auth_service" "dashboard_service" "elevator_service" "maintenance_service" "monitoring_service")

for service in "${SERVICES[@]}"; do
    echo "Setting up virtual environment for $service"
    cd $service
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    cd ..
done

echo "Development environment setup complete!"
