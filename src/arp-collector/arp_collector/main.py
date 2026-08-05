"""Entry point Worker thu thập ARP (7.3). Chạy mỗi giờ (bắt đầu phút 00), tuần tự
(mutex/lock-file chống chạy đa instance — 8.4, cùng quy ước với các Worker PowerShell,
nhưng cài đặt riêng ở Python vì khác runtime).
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from . import device_registry
from .collectors import cisco_ios, fortigate, yamaha_rtx, meraki_mx
from .models import ArpEntry
from .output_writer import write_result

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("arp_collector")

# Điều khiển nhánh thu thập theo ArpDeviceStatus.DeviceType (7.3). Thiết bị có DeviceType
# chưa thiết lập hoặc ngoài định nghĩa này sẽ bị SKIP (xem device_registry.get_target_devices).
DEVICE_TYPE_DISPATCH = {
    "CiscoIOS": cisco_ios.collect,
    "FortiGate": fortigate.collect,
    "YamahaRTX": yamaha_rtx.collect,
    "MerakiMX": meraki_mx.collect,
}


def run() -> None:
    devices = device_registry.get_target_devices()
    all_entries: list[ArpEntry] = []

    for device in devices:
        collect_fn = DEVICE_TYPE_DISPATCH.get(device.device_type)
        if collect_fn is None:
            logger.warning(
                "Thiết bị %s có DeviceType không hợp lệ/chưa thiết lập ('%s') — skip thu thập (7.3).",
                device.device_id, device.device_type,
            )
            device_registry.upsert_device_status(
                device.device_id, success=False,
                error_message=f"DeviceType không hợp lệ: {device.device_type!r}",
            )
            continue

        try:
            # TODO: lấy credential (community/API key) từ SecretStore/credential manager theo
            # device.device_id (Phụ lục E) — KHÔNG truyền giá trị cứng ở đây.
            entries = collect_fn(device, community="")  # type: ignore[call-arg]
            all_entries.extend(entries)
            device_registry.upsert_device_status(device.device_id, success=True)
        except Exception as exc:  # noqa: BLE001 — cấm silent error (8.4): phải log + escalate qua registry
            logger.exception("Thu thập ARP thất bại cho thiết bị %s", device.device_id)
            device_registry.upsert_device_status(device.device_id, success=False, error_message=str(exc))

    write_result(all_entries)
    logger.info("Thu thập ARP xong: %d entry từ %d thiết bị.", len(all_entries), len(devices))


if __name__ == "__main__":
    run()
