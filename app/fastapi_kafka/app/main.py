from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .config.logging import setup_logging
from .mq.kafka import init_producer, close_producer
from .routers import home, health, device, telemetry

setup_logging()
logger = logging.getLogger(__name__)

API_PREFIX = "/api"
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    App startup/shutdown lifecycle.
    - Start Kafka producer at startup (best effort or fail-fast: choose behavior below)
    """
    global KAFKA_READY

    try:
        await init_producer()
        logger.info("Kafka producer initialized successfully.")
    except Exception:
        logger.exception("Kafka initialization failed during startup.")

    try:
        yield
    finally:
        # Always attempt clean shutdown
        try:
            await close_producer()
            logger.info("Kafka producer closed.")
        except Exception:
            logger.exception("Kafka shutdown failed.")


app = FastAPI(
    title="IoT Device Management API",
    version="0.1.0",
    description=(
        "Device Management API for registering IoT devices and handling their "
        "telemetry data. Device-facing endpoints authenticate using device UUIDs "
        "and API keys, while administrative endpoints are intended for internal "
        "operations and tooling."
    ),
    lifespan=lifespan,
)

# ====================
# CORS
# ====================
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_list,
    allow_credentials=False,  # no cookies for devices
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "x-api-key"],
)

# ====================
# Routers
# ====================
app.include_router(home.router, prefix=API_PREFIX)
app.include_router(health.router, prefix=API_PREFIX)
app.include_router(device.router, prefix=API_PREFIX)
app.include_router(telemetry.router, prefix=API_PREFIX)
