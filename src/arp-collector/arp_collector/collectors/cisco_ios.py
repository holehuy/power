"""Thu thập ARP từ Cisco Catalyst (IOS) qua SNMP (7.3).

Lấy ipNetToPhysicalTable bằng pysnmp; fallback sang ipNetToMediaTable nếu thiết bị
không hỗ trợ OID mới. Tham số ban đầu (8.3): timeout 5s/thiết bị, retry 2 lần,
độ song song 1 (tuần tự) — chỉ điều chỉnh song song sau khi có kết quả đo pilot thực tế.
"""

from __future__ import annotations

from datetime import datetime, timezone

from ..models import ArpEntry
from ..device_registry import ArpDevice

SNMP_TIMEOUT_SECONDS = 5
SNMP_RETRIES = 2

OID_IP_NET_TO_PHYSICAL_TABLE = "1.3.6.1.2.1.4.35.1.4"  # ipNetToPhysicalTable
OID_IP_NET_TO_MEDIA_TABLE = "1.3.6.1.2.1.4.22.1.2"  # fallback: ipNetToMediaTable


def collect(device: ArpDevice, *, community: str) -> list[ArpEntry]:
    """Trả về danh sách ArpEntry quét được từ 1 thiết bị Cisco IOS.

    community lấy từ SecretStore theo DeviceId (Phụ lục E — không truyền plaintext qua tham số
    trong code thật, đây chỉ là chữ ký hàm minh hoạ).
    """
    # TODO: dùng pysnmp (hoặc easysnmp) walk OID_IP_NET_TO_PHYSICAL_TABLE với
    # timeout=SNMP_TIMEOUT_SECONDS, retries=SNMP_RETRIES. Nếu thiết bị không hỗ trợ
    # (noSuchObject) -> fallback OID_IP_NET_TO_MEDIA_TABLE.
    raise NotImplementedError("TODO: implement Cisco IOS SNMP collection")
