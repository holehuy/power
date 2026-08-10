"""Thu thập ARP từ Yamaha RTX/NVR qua SNMP (7.3) — cùng cơ chế OID/fallback, tách file
riêng vì Yamaha thường yêu cầu cấu hình SNMP community/ACL riêng theo dòng máy (Phụ lục C.6).

QA (Phụ lục C.6): xác nhận thực tế Yamaha RTX/NVR export ipNetToPhysicalTable/ipNetToMediaTable
chuẩn MIB-II (nhiều dòng RTX chỉ hỗ trợ SNMP read-only cơ bản) trước khi tin cậy hoàn toàn
nhánh OID mới — nếu không hỗ trợ, fallback ipNetToMediaTable trong _walk_arp_table vẫn áp dụng.
"""

from __future__ import annotations

from ..models import ArpEntry
from ..device_registry import ArpDevice
from .cisco_ios import SNMP_TIMEOUT_SECONDS, SNMP_RETRIES, OID_IP_NET_TO_PHYSICAL_TABLE, OID_IP_NET_TO_MEDIA_TABLE
from .cisco_ios import _walk_arp_table


def collect(device: ArpDevice, *, secret: str) -> list[ArpEntry]:
    return _walk_arp_table(device, secret)
