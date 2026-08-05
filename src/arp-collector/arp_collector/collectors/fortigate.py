"""Thu thập ARP từ FortiGate qua SNMP (7.3) — cùng cơ chế OID/fallback như Cisco IOS,
tách file riêng vì có thể khác biệt MIB/OID theo model FortiOS trong thực tế triển khai.

QA (Phụ lục C.6): giả định FortiOS export cùng ipNetToPhysicalTable/ipNetToMediaTable chuẩn
MIB-II như Cisco — cần xác nhận thực tế theo version FortiOS trước khi tin cậy hoàn toàn
(nếu FortiOS dùng OID riêng/khác cấu trúc, cần tách logic parse riêng ở file này thay vì
dùng chung _walk_arp_table).
"""

from __future__ import annotations

from ..models import ArpEntry
from ..device_registry import ArpDevice
from .cisco_ios import SNMP_TIMEOUT_SECONDS, SNMP_RETRIES, OID_IP_NET_TO_PHYSICAL_TABLE, OID_IP_NET_TO_MEDIA_TABLE
from .cisco_ios import _walk_arp_table


def collect(device: ArpDevice, *, secret: str) -> list[ArpEntry]:
    return _walk_arp_table(device, secret)
