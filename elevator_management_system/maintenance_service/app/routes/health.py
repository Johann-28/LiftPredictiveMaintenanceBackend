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
