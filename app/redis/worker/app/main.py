# main.py
from __future__ import annotations

import asyncio
import logging

from .config import get_settings, setup_logging
from .db import async_session_maker
from .models import TelemetryLatestOutbox
from .app_factory import fetch_unprocessed, sync_outbox, sync_telemetry_count

POLL_INTERVAL_SEC = 0.1

setup_logging()
settings = get_settings()
logger = logging.getLogger(__name__)


def format_row(row: TelemetryLatestOutbox) -> str:
    payload_preview = str(row.payload)
    if len(payload_preview) > 220:
        payload_preview = payload_preview[:220] + "..."

    return (
        f"outbox_id={row.outbox_id} "
        f"telemetry_event_id={row.telemetry_event_id} "
        f"device_uuid={row.device_uuid} "
        f"status={row.status} attempts={row.attempts} "
        f"created_at={row.created_at.isoformat()} "
        f"system_time_utc={row.system_time_utc.isoformat()} "
        f"payload={payload_preview}"
    )


async def main() -> None:

    while True:
        try:
            async with async_session_maker() as session:
                telemetry_count = await sync_telemetry_count(session)
                logger.debug(f"Sync telemetry count {telemetry_count}.")

                rows = await fetch_unprocessed(session)
                if not rows:
                    logger.debug("No unprocessed outbox rows.")
                else:
                    logger.debug("Unprocessed outbox rows: %d", len(rows))
                    for r in rows:
                        logger.debug(format_row(r))
                    await sync_outbox(session, rows)

        except Exception:
            logger.exception("Worker error")

        await asyncio.sleep(POLL_INTERVAL_SEC)


if __name__ == "__main__":
    print("Starting outbox worker.")
    asyncio.run(main())
