"""Thu thập ARP từ Cisco Catalyst (IOS) qua SNMP (7.3).

Lấy ipNetToPhysicalTable bằng pysnmp; fallback sang ipNetToMediaTable nếu thiết bị
không hỗ trợ OID mới. Tham số ban đầu (8.3): timeout 5s/thiết bị, retry 2 lần, độ
song song 1 (tuần tự) — chỉ điều chỉnh song song sau khi có kết quả đo pilot thực tế.

QA (đã thêm vào docs/open-questions.md, liên quan Phụ lục C.6):
  - pysnmp>=6.1,<7 (requirements.txt) tái cấu trúc API quanh asyncio ở các bản 6.x; cú pháp
    hlapi chính xác (namespace/tên hàm) cần xác nhận lại khi có môi trường SNMP thật, KHÔNG
    chỉ dựa vào code này — mọi test hiện có đều mock walk_arp_table(), không gọi pysnmp thật.
  - Parse OID của ipNetToPhysicalTable (RFC 4293, chỉ số dạng ifIndex.addrType.InetAddress)
    phức tạp hơn ipNetToMediaTable (RFC 1213, chỉ số = ifIndex.a.b.c.d thẳng theo IPv4).
    Hàm _parse_physical_table dưới đây giả định phần đuôi OID vẫn là 4 octet IPv4 liền
    nhau (đúng với nhiều thiết bị triển khai thực tế nhưng KHÔNG phải mọi trường hợp theo
    chuẩn RFC) — xác nhận với output thật của thiết bị Cisco tại C.6 trước khi tin tưởng
    hoàn toàn nhánh ipNetToPhysicalTable; nếu lệch, sản phẩm vẫn đúng nhờ fallback
    ipNetToMediaTable (đơn giản, ổn định hơn).
"""

from __future__ import annotations

from datetime import datetime, timezone

from pysnmp.hlapi import (
    CommunityData,
    ContextData,
    ObjectIdentity,
    ObjectType,
    SnmpEngine,
    UdpTransportTarget,
    nextCmd,
)

from ..models import ArpEntry
from ..device_registry import ArpDevice

SNMP_TIMEOUT_SECONDS = 5
SNMP_RETRIES = 2
SNMP_PORT = 161

OID_IP_NET_TO_PHYSICAL_TABLE = "1.3.6.1.2.1.4.35.1.4"  # ipNetToPhysicalTable
OID_IP_NET_TO_MEDIA_TABLE = "1.3.6.1.2.1.4.22.1.2"  # fallback: ipNetToMediaTable


def _format_mac(raw_bytes: bytes) -> str:
    return ":".join(f"{b:02x}" for b in raw_bytes)


def _parse_media_table(oid_suffix: list[int], value_bytes: bytes) -> str | None:
    """ipNetToMediaTable: chỉ số = ifIndex.a.b.c.d (4 octet cuối là IPv4 trực tiếp, RFC 1213)."""
    if len(oid_suffix) < 4:
        return None
    ip_octets = oid_suffix[-4:]
    if any(o < 0 or o > 255 for o in ip_octets):
        return None
    return ".".join(str(o) for o in ip_octets)


def _walk_oid(
    device: ArpDevice,
    secret: str,
    base_oid: str,
) -> list[tuple[str, bytes]]:
    """Walk 1 bảng SNMP, trả về list (ip_address, mac_bytes). Raise nếu lỗi kết nối/timeout sau
    khi hết retry — main.py sẽ tính đây là 1 lần thất bại thu thập của thiết bị (7.3/8.4).
    """
    results: list[tuple[str, bytes]] = []
    iterator = nextCmd(
        SnmpEngine(),
        CommunityData(secret, mpModel=1),  # mpModel=1 -> SNMPv2c (xác định ở v1.3, Phụ lục E)
        UdpTransportTarget(
            (device.device_fqdn, SNMP_PORT),
            timeout=SNMP_TIMEOUT_SECONDS,
            retries=SNMP_RETRIES,
        ),
        ContextData(),
        ObjectType(ObjectIdentity(base_oid)),
        lexicographicMode=False,
    )

    for error_indication, error_status, error_index, var_binds in iterator:
        if error_indication:
            raise RuntimeError(f"SNMP lỗi kết nối tới {device.device_fqdn}: {error_indication}")
        if error_status:
            # noSuchObject/noSuchInstance khi hết bảng hoặc thiết bị không hỗ trợ OID này —
            # KHÔNG raise, để collect() quyết định fallback sang OID cũ.
            break

        for var_bind in var_binds:
            oid, value = var_bind
            oid_tuple = oid.getOid()
            base_len = len(ObjectIdentity(base_oid).resolveWithMib(None).getOid())
            oid_suffix = list(oid_tuple[base_len:])
            ip_address = _parse_media_table(oid_suffix, bytes(value))
            if ip_address is None:
                continue
            mac_bytes = bytes(value)
            if len(mac_bytes) == 6:
                results.append((ip_address, mac_bytes))

    return results


def _walk_arp_table(device: ArpDevice, secret: str) -> list[ArpEntry]:
    """Dùng chung cho Cisco/FortiGate/Yamaha (7.3: "cùng cơ chế OID/fallback"). Thử OID mới trước,
    fallback OID cũ nếu bảng rỗng (thiết bị không hỗ trợ ipNetToPhysicalTable)."""
    raw = _walk_oid(device, secret, OID_IP_NET_TO_PHYSICAL_TABLE)
    if not raw:
        raw = _walk_oid(device, secret, OID_IP_NET_TO_MEDIA_TABLE)

    observed_at = datetime.now(timezone.utc)
    return [
        ArpEntry(
            ip_address=ip_address,
            mac_address=_format_mac(mac_bytes),
            observed_at=observed_at,
            device_id=device.device_id,
        )
        for ip_address, mac_bytes in raw
    ]


def collect(device: ArpDevice, *, secret: str) -> list[ArpEntry]:
    """Trả về danh sách ArpEntry quét được từ 1 thiết bị Cisco IOS.

    secret: SNMP community string, lấy từ secret_store.get_device_secret(device.device_id)
    (Phụ lục E — main.py chịu trách nhiệm lấy secret, KHÔNG hard-code ở đây).
    """
    return _walk_arp_table(device, secret)
