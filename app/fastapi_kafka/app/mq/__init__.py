# mq/__init__.py
from .kafka import init_producer, close_producer, get_producer, send_and_wait

__all__ = [
    "init_producer",
    "get_producer",
    "close_producer",
    "send_and_wait",
]
