import asyncio
import json
import logging
import socket
import ssl
from typing import Optional, Any

from kafka import KafkaProducer
from kafka.errors import KafkaError
from aws_msk_iam_sasl_signer import MSKAuthTokenProvider

from ..config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

_producer: Optional[KafkaProducer] = None


class MSKTokenProvider():
    def token(self):
        token, _ = MSKAuthTokenProvider.generate_auth_token('<my AWS Region>')
        return token

tp = MSKTokenProvider()

producer = KafkaProducer(
    bootstrap_servers='<myBootstrapString>',
    security_protocol='SASL_SSL',
    sasl_mechanism='OAUTHBEARER',
    sasl_oauth_token_provider=tp,
    client_id=socket.gethostname(),
)


async def close_producer() -> None:
    global _producer
    if _producer is None:
        return

    # flush/close are blocking
    try:
        producer.flush()
    finally:
        producer.close()
        logger.info("Kafka producer closed.")


def get_producer() -> KafkaProducer:
    if _producer is None:
        raise RuntimeError("Kafka producer not initialized (startup failed?)")
    return _producer


async def send_and_wait(topic: str, key: Any, value: Any, timeout: float = 10.0) -> None:
    """
    kafka-python send() returns a Future; waiting is blocking -> run in thread.
    """
    producer = get_producer()

    def _send_blocking():
        fut = producer.send(topic, key=key, value=value)
        # Block until acknowledged or timeout
        fut.get(timeout=timeout)

    try:
        await asyncio.to_thread(_send_blocking)
    except KafkaError as e:
        logger.exception("KafkaError sending message")
        raise
