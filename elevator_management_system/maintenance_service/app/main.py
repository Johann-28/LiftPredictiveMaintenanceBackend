"""
maintenance_service - Elevator Management System
FastAPI microservice for maintenance service
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
    logger.info("Starting maintenance_service...")
    await init_db()
    yield
    # Shutdown
    logger.info("Shutting down maintenance_service...")
    await close_db()

# Create FastAPI app
app = FastAPI(
    title="maintenance service Service",
    description="Microservice for maintenance service management",
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
    return {"message": "Welcome to maintenance_service", "status": "running"}

if _name_ == "_main_":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8004,
        reload=True
    )
