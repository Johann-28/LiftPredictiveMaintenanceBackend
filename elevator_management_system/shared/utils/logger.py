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
