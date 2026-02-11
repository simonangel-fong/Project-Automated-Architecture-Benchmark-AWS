# app_factory/func.py
from __future__ import annotations

import json
import logging
from typing import Sequence, Iterable

from sqlalchemy import select, update, func
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import TelemetryLatestOutbox, TelemetryEvent
from ..db.redis import redis_client

logger = logging.getLogger(__name__)

BATCH_SIZE = 1000
TELEMETRY_COUNT_KEY = "telemetry:count"
TELEMETRY_LATEST = "telemetry:latest"
LUA_SET_IF_NEWER = """
local data_key = KEYS[1]
local ver_key  = KEYS[2]
local incoming = tonumber(ARGV[1])
local current  = tonumber(redis.call('GET', ver_key) or '0')

if incoming > current then
  redis.call('SET', data_key, ARGV[2])
  redis.call('SET', ver_key, ARGV[1])
  return 1
end
return 0
"""

_lua_sha: str | None = None


async def _get_lua_sha() -> str:
    global _lua_sha
    if _lua_sha is None:
        _lua_sha = await redis_client.script_load(LUA_SET_IF_NEWER)
    return _lua_sha


def _redis_keys(device_uuid: str) -> tuple[str, str]:
    data_key = f"{TELEMETRY_LATEST}:{device_uuid}"
    ver_key = f"{data_key}:ver"
    return data_key, ver_key


async def fetch_unprocessed(session: AsyncSession) -> Sequence[TelemetryLatestOutbox]:
    """
    Fetch outbox rows that are not processed yet.
    """
    stmt = (
        select(TelemetryLatestOutbox)
        .where(TelemetryLatestOutbox.status != "PROCESSED")
        .order_by(TelemetryLatestOutbox.created_at.asc())
        .limit(BATCH_SIZE)
    )
    result = await session.execute(stmt)
    return result.scalars().all()


async def sync_outbox(
    session: AsyncSession,
    rows: Iterable[TelemetryLatestOutbox],
) -> int:
    """
    Sync unprocessed outbox rows to Redis and mark them PROCESSED in Postgres.

    Returns:
        count of rows marked PROCESSED
    """
    sha = await _get_lua_sha()
    processed_ids: list[int] = []
    processed_count = 0

    for r in rows:
        device_uuid_str = str(r.device_uuid)
        data_key, ver_key = _redis_keys(device_uuid_str)

        # parse json into string
        payload_json = json.dumps(
            r.payload, separators=(",", ":"), default=str)

        try:
            updated = await redis_client.evalsha(
                sha,
                2,
                data_key,
                ver_key,
                str(r.telemetry_event_id),  # version
                payload_json,
            )

            processed_ids.append(r.outbox_id)
            processed_count += 1

            if updated == 1:
                logger.debug("Redis updated device=%s version=%s",
                             device_uuid_str, r.telemetry_event_id)
            else:
                logger.debug("Redis skipped (older) device=%s version=%s",
                             device_uuid_str, r.telemetry_event_id)

        except Exception as e:
            # Leave it unprocessed so it can be retried next poll
            logger.exception(
                "Redis sync failed outbox_id=%s device=%s", r.outbox_id, device_uuid_str)

            await session.execute(
                update(TelemetryLatestOutbox)
                .where(TelemetryLatestOutbox.outbox_id == r.outbox_id)
                .values(
                    attempts=TelemetryLatestOutbox.attempts + 1,
                    last_error=str(e),
                    status="FAILED",
                )
            )

    # Mark processed rows in a single UPDATE (fast)
    if processed_ids:
        await session.execute(
            update(TelemetryLatestOutbox)
            .where(TelemetryLatestOutbox.outbox_id.in_(processed_ids))
            .values(status="PROCESSED", processed_at=__import__("sqlalchemy").sql.func.now())
        )

    await session.commit()

    return processed_count


async def sync_telemetry_count(session: AsyncSession) -> int:
    """
    Read total telemetry event count from Postgres and write it to Redis.

    Returns:
        The telemetry_count written to Redis.
    """
    stmt = select(func.count()).select_from(TelemetryEvent)
    result = await session.execute(stmt)
    telemetry_count = int(result.scalar_one())

    # Store as string (Redis stores strings); easy to INCR/GET later too
    await redis_client.set(TELEMETRY_COUNT_KEY, str(telemetry_count))

    logger.debug("Synced telemetry count to Redis: %s=%d",
                 TELEMETRY_COUNT_KEY, telemetry_count)
    return telemetry_count
