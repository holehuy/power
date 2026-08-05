"""Thu thập client list từ Meraki MX qua Meraki Dashboard API (7.3) — KHÔNG dùng SNMP.

Gọi GET /networks/{MerakiNetworkId}/clients bằng Meraki SDK chính thức. Chỉ dùng
ArpDeviceStatus.MerakiNetworkId để gọi API (nguyên tắc 1 thiết bị = 1 network, 6.9).
MerakiOrgId CHỈ dùng để ghi nhận sổ quản lý/vận hành — KHÔNG được tham chiếu trong
xử lý thu thập ở đây (làm rõ ở v1.4).
"""

from __future__ import annotations

from ..models import ArpEntry
from ..device_registry import ArpDevice


def collect(device: ArpDevice, *, api_key: str) -> list[ArpEntry]:
    """api_key: Meraki Dashboard API key, quyền Read-Only (8.2/9.2), lấy từ SecretStore."""
    if not device.meraki_network_id:
        raise ValueError(f"Thiết bị {device.device_id} là MerakiMX nhưng thiếu MerakiNetworkId (6.9).")
    # TODO: dùng thư viện `meraki` (SDK chính thức) gọi
    # meraki.DashboardAPI(api_key).networks.getNetworkClients(device.meraki_network_id).
    # Lưu ý C.2: xác nhận rate-limit đủ để scan toàn bộ MX trong 1 chu kỳ (1-3 giờ).
    raise NotImplementedError("TODO: implement Meraki Dashboard API collection")
