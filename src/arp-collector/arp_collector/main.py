"""Entry point Worker thu thập ARP (7.3). Chạy mỗi giờ (bắt đầu phút 00), tuần tự
(mutex/lock-file chống chạy đa instance — 8.4, cùng quy ước với các Worker PowerShell,
nhưng cài đặt riêng ở Python vì khác runtime).
"""

from __future__ import annotations

import logging

from . import device_registry, secret_store, worker_lock
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


def _process_device(device, all_entries: list[ArpEntry]) -> None:
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
        return

    try:
        secret = secret_store.get_device_secret(device.device_id)  # Phụ lục E — community SNMP / API key Meraki
        entries = collect_fn(device, secret=secret)
        all_entries.extend(entries)
        device_registry.upsert_device_status(device.device_id, success=True)
    except Exception as exc:  # noqa: BLE001 — cấm silent error (8.4): phải log + escalate qua registry
        logger.exception("Thu thập ARP thất bại cho thiết bị %s", device.device_id)
        device_registry.upsert_device_status(device.device_id, success=False, error_message=str(exc))


def run() -> None:
    devices = device_registry.get_target_devices()
    all_entries: list[ArpEntry] = []

    for device in devices:
        try:
            _process_device(device, all_entries)
        except Exception:
            # QA: lớp bảo vệ ngoài cùng — nếu chính upsert_device_status() (ghi Graph API) thất bại,
            # KHÔNG được để crash toàn bộ chu kỳ và bỏ dở các thiết bị còn lại (8.4: cô lập sự cố
            # theo đơn vị thiết bị, không phải theo đơn vị chu kỳ). Lỗi vẫn log đầy đủ, không silent.
            logger.exception(
                "Lỗi không mong đợi khi xử lý thiết bị %s — bỏ qua, tiếp tục thiết bị kế tiếp.",
                device.device_id,
            )

    write_result(all_entries)
    logger.info("Thu thập ARP xong: %d entry từ %d thiết bị.", len(all_entries), len(devices))


if __name__ == "__main__":
    # Lock bao trùm CẢ 2 pha (Python + PowerShell reflect, cùng 1 Task) — PowerShell là bên giải
    # phóng ở cuối (Exit-WorkerLock trong Invoke-ReflectArpResults.ps1), xem worker_lock.py.
    try:
        worker_lock.acquire_lock()
    except RuntimeError as exc:
        logger.warning(str(exc))
    else:
        run()
