#!/bin/bash

# Script para construir el proyecto de microservicios de gestión de elevadores
# Autor: Assistant
# Fecha: $(date)

set -e  # Detener el script si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar si Python está instalado
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 no está instalado. Por favor instala Python 3.8+"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version | cut -d" " -f2 | cut -d"." -f1-2)
    print_status "Python versión detectada: $PYTHON_VERSION"
    
    if [[ $(echo "$PYTHON_VERSION <= 3.8" | bc -l) -eq 0 ]]; then
        print_error "Se requiere Python 3.8 o superior"
        exit 1
    fi
}

# Verificar si Docker está instalado
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_warning "Docker no está instalado. Algunas funcionalidades pueden no estar disponibles."
        return 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_warning "Docker Compose no está instalado. Algunas funcionalidades pueden no estar disponibles."
        return 1
    fi
    
    print_status "Docker y Docker Compose detectados"
    return 0
}

# Crear la estructura de directorios
create_directory_structure() {
    print_header "Creando estructura de directorios"
    
    PROJECT_NAME="elevator_management_system"
    
    # Directorio principal
    mkdir -p $PROJECT_NAME
    cd $PROJECT_NAME
    
    # Crear estructura de microservicios
    SERVICES=("gateway" "auth_service" "dashboard_service" "elevator_service" "maintenance_service" "monitoring_service")
    
    for service in "${SERVICES[@]}"; do
        print_status "Creando estructura para $service"
        
        # Directorios principales del servicio
        mkdir -p $service/{app,tests}
        mkdir -p $service/app/{models,routes,services,database,middleware,utils}
        
        # Si es gateway, crear directorios adicionales
        if [ "$service" = "gateway" ]; then
            mkdir -p $service/app/{proxy,load_balancer}
        fi
        
        # Si es elevator_service, crear directorio websocket
        if [ "$service" = "elevator_service" ]; then
            mkdir -p $service/app/websocket
        fi
        
        # Si es monitoring_service, crear directorios para métricas
        if [ "$service" = "monitoring_service" ]; then
            mkdir -p $service/app/{collectors,processors,analytics}
        fi
    done
    
    # Crear directorios compartidos
    mkdir -p shared/{models,utils,database,middleware,exceptions}
    
    # Crear directorios para configuración
    mkdir -p config/{nginx,redis,postgres,mongodb,influxdb}
    
    # Crear directorios para scripts
    mkdir -p scripts/{deployment,migration,backup}
    
    # Crear directorios para documentación
    mkdir -p docs/{api,architecture,deployment}
    
    print_status "Estructura de directorios creada exitosamente"
}

# Crear archivos base para cada microservicio
create_base_files() {
    print_header "Creando archivos base"
    
    # requirements.txt global
    cat > requirements.txt << 'EOF'
# Core FastAPI dependencies
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
pydantic-settings==2.1.0

# Database
sqlalchemy==2.0.23
alembic==1.13.1
asyncpg==0.29.0
redis==5.0.1
motor==3.3.2
influxdb-client==1.39.0

# Authentication & Security
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6

# HTTP & Networking
httpx==0.25.2
websockets==12.0

# Monitoring & Logging
prometheus-client==0.19.0
structlog==23.2.0

# Development & Testing
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-cov==4.1.0
black==23.11.0
isort==5.12.0
flake8==6.1.0

# Utils
python-dotenv==1.0.0
celery==5.3.4
aiofiles==23.2.1
EOF

    # Crear archivos para cada servicio
    SERVICES=("gateway" "auth_service" "dashboard_service" "elevator_service" "maintenance_service" "monitoring_service")
    PORTS=(8000 8001 8002 8003 8004 8005)
    
    for i in "${!SERVICES[@]}"; do
        service="${SERVICES[$i]}"
        port="${PORTS[$i]}"
        
        print_status "Creando archivos base para $service"
        
        # main.py
        create_main_file "$service" "$port"
        
        # _init_.py files
        touch $service/app/_init_.py
        touch $service/app/models/_init_.py
        touch $service/app/routes/_init_.py
        touch $service/app/services/_init_.py
        touch $service/app/database/_init_.py
        touch $service/tests/_init_.py
        
        # requirements.txt específico
        cp requirements.txt $service/requirements.txt
        
        # Dockerfile
        create_dockerfile "$service" "$port"
        
        # .env
        create_env_file "$service" "$port"
        
        # conftest.py para tests
        create_conftest_file "$service"
    done
    
    # Crear archivos compartidos
    create_shared_files
    
    # Crear docker-compose.yml
    create_docker_compose
    
    # Crear scripts de utilidad
    create_utility_scripts
    
    print_status "Archivos base creados exitosamente"
}

# Función para crear main.py de cada servicio
create_main_file() {
    local service=$1
    local port=$2
    
    cat > $service/app/main.py << EOF
"""
$service - Elevator Management System
FastAPI microservice for ${service//_/ }
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import logging
from contextlib import asynccontextmanager

from .database.connection import init_db, close_db
from .routes import health
# Import other routes here

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(_name_)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting $service...")
    await init_db()
    yield
    # Shutdown
    logger.info("Shutting down $service...")
    await close_db()

# Create FastAPI app
app = FastAPI(
    title="${service//_/ } Service",
    description="Microservice for ${service//_/ } management",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

# Include routers
app.include_router(health.router, prefix="/health", tags=["health"])
# Add other routers here

@app.get("/")
async def root():
    return {"message": "Welcome to $service", "status": "running"}

if _name_ == "_main_":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=$port,
        reload=True
    )
EOF

    # Crear route de health check
    cat > $service/app/routes/health.py << 'EOF'
"""
Health check routes
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..database.connection import get_db

router = APIRouter()

@router.get("/")
async def health_check():
    return {"status": "healthy", "service": "running"}

@router.get("/db")
async def health_check_db(db: Session = Depends(get_db)):
    try:
        # Simple database query to check connection
        result = await db.execute("SELECT 1")
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": "disconnected", "error": str(e)}
EOF

    touch $service/app/routes/_init_.py
}

# Función para crear Dockerfile
create_dockerfile() {
    local service=$1
    local port=$2
    
    cat > $service/Dockerfile << EOF
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    gcc \\
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY ./app ./app

# Create non-root user
RUN useradd --create-home --shell /bin/bash appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE $port

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \\
    CMD curl -f http://localhost:$port/health || exit 1

# Run the application
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "$port"]
EOF
}

# Función para crear archivo .env
create_env_file() {
    local service=$1
    local port=$2
    
    cat > $service/.env << EOF
# $service Environment Variables

# Service Configuration
SERVICE_NAME=$service
SERVICE_PORT=$port
SERVICE_HOST=0.0.0.0
DEBUG=True
LOG_LEVEL=INFO

# Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/${service}_db
REDIS_URL=redis://localhost:6379/0

# Security
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# External Services
EOF

    if [ "$service" = "monitoring_service" ]; then
        echo "INFLUXDB_URL=http://localhost:8086" >> $service/.env
        echo "INFLUXDB_TOKEN=your-influxdb-token" >> $service/.env
        echo "INFLUXDB_ORG=elevator-org" >> $service/.env
        echo "INFLUXDB_BUCKET=elevator-metrics" >> $service/.env
    fi
    
    if [ "$service" = "elevator_service" ]; then
        echo "MONGODB_URL=mongodb://localhost:27017" >> $service/.env
        echo "MONGODB_DB=elevator_logs" >> $service/.env
    fi
}

# Función para crear conftest.py
create_conftest_file() {
    local service=$1
    
    cat > $service/tests/conftest.py << 'EOF'
"""
Test configuration and fixtures
"""

import pytest
import asyncio
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.database.connection import get_db, Base

# Test database URL
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture
def client(db):
    def override_get_db():
        try:
            yield db
        finally:
            db.close()
    
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
EOF
}

# Función para crear archivos compartidos
create_shared_files() {
    print_status "Creando archivos compartidos"
    
    # Shared models
    cat > shared/models/base.py << 'EOF'
"""
Base models for shared use across microservices
"""

from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from enum import Enum

class BaseResponse(BaseModel):
    success: bool
    message: str
    timestamp: datetime = datetime.now()

class PaginationParams(BaseModel):
    page: int = 1
    size: int = 20
    
class SortParams(BaseModel):
    field: str = "created_at"
    direction: str = "desc"

class HealthStatus(BaseModel):
    status: str
    timestamp: datetime
    version: str
    uptime: float

class AlertSeverity(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"
EOF

    # Shared database connection
    cat > shared/database/base.py << 'EOF'
"""
Base database configuration
"""

from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./app.db")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
metadata = MetaData()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def init_db():
    # Create tables
    Base.metadata.create_all(bind=engine)

async def close_db():
    # Close database connections
    engine.dispose()
EOF

    # Shared utilities
    cat > shared/utils/logger.py << 'EOF'
"""
Logging utilities
"""

import logging
import structlog
import sys
from typing import Any, Dict

def setup_logging(service_name: str, log_level: str = "INFO") -> None:
    """Setup structured logging for the service"""
    
    timestamper = structlog.processors.TimeStamper(fmt="ISO")
    
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            timestamper,
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer()
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    
    # Configure standard library logging
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=getattr(logging, log_level.upper()),
    )
    
    # Add service name to all logs
    structlog.configure(
        context_class=dict,
        initial_context={"service": service_name}
    )

def get_logger(name: str = None) -> Any:
    """Get a structured logger instance"""
    return structlog.get_logger(name)
EOF

    touch shared/_init_.py
    touch shared/models/_init_.py
    touch shared/utils/_init_.py
    touch shared/database/_init_.py
}

# Función para crear docker-compose.yml
create_docker_compose() {
    print_status "Creando docker-compose.yml"
    
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # API Gateway
  gateway:
    build: ./gateway
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/gateway_db
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - postgres
      - redis
      - auth-service
      - dashboard-service
      - elevator-service
      - maintenance-service
      - monitoring-service
    networks:
      - elevator-network

  # Authentication Service
  auth-service:
    build: ./auth_service
    ports:
      - "8001:8001"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/auth_db
      - REDIS_URL=redis://redis:6379/1
    depends_on:
      - postgres
      - redis
    networks:
      - elevator-network

  # Dashboard Service
  dashboard-service:
    build: ./dashboard_service
    ports:
      - "8002:8002"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/dashboard_db
      - REDIS_URL=redis://redis:6379/2
    depends_on:
      - postgres
      - redis
    networks:
      - elevator-network

  # Elevator Service
  elevator-service:
    build: ./elevator_service
    ports:
      - "8003:8003"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/elevator_db
      - MONGODB_URL=mongodb://mongodb:27017
      - REDIS_URL=redis://redis:6379/3
    depends_on:
      - postgres
      - mongodb
      - redis
    networks:
      - elevator-network

  # Maintenance Service
  maintenance-service:
    build: ./maintenance_service
    ports:
      - "8004:8004"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/maintenance_db
      - REDIS_URL=redis://redis:6379/4
    depends_on:
      - postgres
      - redis
    networks:
      - elevator-network

  # Monitoring Service
  monitoring-service:
    build: ./monitoring_service
    ports:
      - "8005:8005"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/monitoring_db
      - INFLUXDB_URL=http://influxdb:8086
      - REDIS_URL=redis://redis:6379/5
    depends_on:
      - postgres
      - influxdb
      - redis
    networks:
      - elevator-network

  # Databases
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./config/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - elevator-network

  mongodb:
    image: mongo:6
    environment:
      MONGO_INITDB_ROOT_USERNAME: user
      MONGO_INITDB_ROOT_PASSWORD: password
    volumes:
      - mongodb_data:/data/db
    ports:
      - "27017:27017"
    networks:
      - elevator-network

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    networks:
      - elevator-network

  influxdb:
    image: influxdb:2.7
    environment:
      INFLUXDB_DB: elevator_metrics
      INFLUXDB_ADMIN_USER: admin
      INFLUXDB_ADMIN_PASSWORD: password
      INFLUXDB_USER: user
      INFLUXDB_USER_PASSWORD: password
    volumes:
      - influxdb_data:/var/lib/influxdb2
    ports:
      - "8086:8086"
    networks:
      - elevator-network

  # Nginx (Load Balancer)
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config/nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - gateway
    networks:
      - elevator-network

volumes:
  postgres_data:
  mongodb_data:
  redis_data:
  influxdb_data:

networks:
  elevator-network:
    driver: bridge
EOF

    # Crear configuración de PostgreSQL
    mkdir -p config/postgres
    cat > config/postgres/init.sql << 'EOF'
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
EOF

    # Crear configuración básica de Nginx
    mkdir -p config/nginx
    cat > config/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream gateway {
        server gateway:8000;
    }
    
    server {
        listen 80;
        
        location / {
            proxy_pass http://gateway;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF
}

# Función para crear scripts de utilidad
create_utility_scripts() {
    print_status "Creando scripts de utilidad"
    
    # Script de desarrollo
    cat > scripts/dev-setup.sh << 'EOF'
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
EOF

    # Script para correr todos los servicios
    cat > scripts/run-all.sh << 'EOF'
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
EOF

    # Script para tests
    cat > scripts/run-tests.sh << 'EOF'
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
EOF

    # Hacer scripts ejecutables
    chmod +x scripts/*.sh
}

# Función principal
main() {
    print_header "ELEVATOR MANAGEMENT SYSTEM SETUP"
    
    echo "Este script creará la estructura completa del proyecto de microservicios"
    echo "para el sistema de gestión de elevadores usando FastAPI."
    echo ""
    
    read -p "¿Deseas continuar? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelado por el usuario"
        exit 0
    fi
    
    # Verificar dependencias
    print_header "Verificando dependencias"
    check_python
    
    HAS_DOCKER=0
    if check_docker; then
        HAS_DOCKER=1
    fi
    
    # Crear estructura del proyecto
    create_directory_structure
    create_base_files
    
    print_header "SETUP COMPLETADO"
    print_status "Proyecto creado exitosamente!"
    print_status "Directorio del proyecto: $(pwd)/elevator_management_system"
    
    echo ""
    echo "Próximos pasos:"
    echo "1. cd elevator_management_system"
    echo "2. Configurar las variables de entorno en cada servicio"
    echo "3. Para desarrollo local:"
    echo "   - chmod +x scripts/dev-setup.sh"
    echo "   - ./scripts/dev-setup.sh"
    echo "   - ./scripts/run-all.sh"
    
    if [ $HAS_DOCKER -eq 1 ]; then
        echo "4. Para usar Docker:"
        echo "   - docker-compose up --build"
    fi
    
    echo ""
    echo "5. Para ejecutar tests:"
    echo "   - ./scripts/run-tests.sh"
    
    print_status "¡Listo para comenzar el desarrollo!"
}

# Ejecutar función principal
main "$@"