"""Thu thập ARP từ FortiGate qua SNMP (7.3) — cùng cơ chế OID/fallback như Cisco IOS,
tách file riêng vì có thể khác biệt MIB/OID theo model FortiOS trong thực tế triển khai.
"""

from __future__ import annotations

from ..models import ArpEntry
from ..device_registry import ArpDevice
from .cisco_ios import SNMP_TIMEOUT_SECONDS, SNMP_RETRIES, OID_IP_NET_TO_PHYSICAL_TABLE, OID_IP_NET_TO_MEDIA_TABLE


def collect(device: ArpDevice, *, community: str) -> list[ArpEntry]:
    # TODO: giống cisco_ios.collect() — walk OID_IP_NET_TO_PHYSICAL_TABLE, fallback
    # OID_IP_NET_TO_MEDIA_TABLE nếu cần. Kiểm tra thực tế FortiOS version trong Phụ lục C.6
    # trước khi giả định cùng OID với Cisco.
    raise NotImplementedError("TODO: implement FortiGate SNMP collection")
