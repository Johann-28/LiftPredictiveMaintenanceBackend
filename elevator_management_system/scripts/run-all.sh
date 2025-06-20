#!/bin/bash

# Script to run all services in development mode

SERVICES=("auth_service" "dashboard_service" "elevator_service" "maintenance_service" "monitoring_service" "gateway")
PORTS=(8001 8002 8003 8004 8005 8000)

echo "Starting all microservices..."

for i in "${!SERVICES[@]}"; do
    service="${SERVICES[$i]}"
    port="${PORTS[$i]}"
    
    echo "Starting $service on port $port"
    cd $service
    source venv/bin/activate
    python app/main.py &
    cd ..
    
    sleep 2
done

echo "All services started!"
echo "Gateway running on http://localhost:8000"

# Wait for user input to stop services
read -p "Press enter to stop all services..."

# Kill all background processes
jobs -p | xargs kill
