"""Thu thập client list từ Meraki MX qua Meraki Dashboard API (7.3) — KHÔNG dùng SNMP.

Gọi GET /networks/{MerakiNetworkId}/clients bằng Meraki SDK chính thức. Chỉ dùng
ArpDeviceStatus.MerakiNetworkId để gọi API (nguyên tắc 1 thiết bị = 1 network, 6.9).
MerakiOrgId CHỈ dùng để ghi nhận sổ quản lý/vận hành — KHÔNG được tham chiếu trong
xử lý thu thập ở đây (làm rõ ở v1.4).

QA (Phụ lục C.2, đã tracked ở docs/open-questions.md): giới hạn rate-limit Meraki Dashboard
API thực tế (số org/network/MX) chưa xác nhận — timespan=3600s (khớp chu kỳ 1 giờ, 7.3) có
thể cần nới ra (vd 7200s) nếu chu kỳ hay bị skip do lock đa instance (8.4); quyết định cuối
cùng chờ đo thực tế theo C.2.
"""

from __future__ import annotations

from datetime import datetime, timezone

import meraki

from ..models import ArpEntry
from ..device_registry import ArpDevice

CLIENT_LOOKBACK_SECONDS = 3600  # khớp chu kỳ thu thập 1 giờ (7.3) — xem QA ở trên về C.2


def collect(device: ArpDevice, *, secret: str) -> list[ArpEntry]:
    """secret: Meraki Dashboard API key, quyền Read-Only (8.2/9.2), lấy từ secret_store theo
    device.device_id (Phụ lục E)."""
    if not device.meraki_network_id:
        raise ValueError(f"Thiết bị {device.device_id} là MerakiMX nhưng thiếu MerakiNetworkId (6.9).")

    dashboard = meraki.DashboardAPI(
        api_key=secret,
        suppress_logging=True,
        print_console=False,
        maximum_retries=2,  # nhất quán với retry=2 lần dùng cho SNMP (8.3) — Meraki SDK tự lo backoff nội bộ
    )
    clients = dashboard.networks.getNetworkClients(
        device.meraki_network_id,
        total_pages="all",
        timespan=CLIENT_LOOKBACK_SECONDS,
    )

    entries: list[ArpEntry] = []
    for client in clients:
        ip_address = client.get("ip")
        mac_address = client.get("mac")
        if not ip_address or not mac_address:
            continue  # client không có lease IPv4 hiện hành (vd chỉ IPv6, hoặc đã rời mạng)

        last_seen_raw = client.get("lastSeen")
        observed_at = (
            datetime.fromisoformat(last_seen_raw.replace("Z", "+00:00"))
            if last_seen_raw
            else datetime.now(timezone.utc)
        )
        entries.append(
            ArpEntry(
                ip_address=ip_address,
                mac_address=mac_address,
                observed_at=observed_at,
                device_id=device.device_id,
            )
        )
    return entries
