"""Thu thập ARP từ Yamaha RTX/NVR qua SNMP (7.3) — cùng cơ chế OID/fallback, tách file
riêng vì Yamaha thường yêu cầu cấu hình SNMP community/ACL riêng theo dòng máy (Phụ lục C.6).
"""

from __future__ import annotations

from ..models import ArpEntry
from ..device_registry import ArpDevice
from .cisco_ios import SNMP_TIMEOUT_SECONDS, SNMP_RETRIES, OID_IP_NET_TO_PHYSICAL_TABLE, OID_IP_NET_TO_MEDIA_TABLE


def collect(device: ArpDevice, *, community: str) -> list[ArpEntry]:
    # TODO: giống cisco_ios.collect().
    raise NotImplementedError("TODO: implement Yamaha RTX/NVR SNMP collection")
