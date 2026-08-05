"""Kiểu dữ liệu dùng chung giữa các collector và main.py."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime


@dataclass
class ArpEntry:
    ip_address: str
    mac_address: str
    observed_at: datetime  # dùng để tính LastSeenAt (ISO 8601 kèm offset JST, 6.8)
    device_id: str  # thiết bị nào phát hiện ra entry này (ArpDeviceStatus.DeviceId)
