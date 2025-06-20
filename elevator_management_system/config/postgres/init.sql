-- Initialize databases for each microservice
CREATE DATABASE gateway_db;
CREATE DATABASE auth_db;
CREATE DATABASE dashboard_db;
CREATE DATABASE elevator_db;
CREATE DATABASE maintenance_db;
CREATE DATABASE monitoring_db;

-- Create users if needed
-- CREATE USER service_user WITH PASSWORD 'service_password';
-- GRANT ALL PRIVILEGES ON DATABASE gateway_db TO service_user;
