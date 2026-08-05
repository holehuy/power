"""Test cho arp_collector.main — mock hoàn toàn device_registry và các collector,
KHÔNG gọi SNMP/Meraki API thật trong CI (thiết bị thật chỉ dùng ở môi trường kiểm thử
thực tế, xem Phụ lục C.6).
"""

from __future__ import annotations

import sys
from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).parent.parent.parent / "src" / "arp-collector"))

from arp_collector import main as arp_main  # noqa: E402
from arp_collector.device_registry import ArpDevice  # noqa: E402
from arp_collector.models import ArpEntry  # noqa: E402


def _make_device(device_type: str) -> ArpDevice:
    return ArpDevice(
        device_id="test-device-01",
        device_name="Test Device",
        device_fqdn="test-device-01.ad.nkc.co.jp",
        device_type=device_type,
        meraki_org_id=None,
        meraki_network_id=None,
        target_segments=["10.0.0.0/24"],
        consecutive_failure_count=0,
        current_status="OK",
    )


def test_skips_device_with_invalid_device_type():
    """Thiết bị DeviceType ngoài định nghĩa phải bị SKIP, không được raise ra ngoài (7.3, bổ sung v1.4)."""
    device = _make_device("SomeUnknownVendor")

    with patch.object(arp_main.device_registry, "get_target_devices", return_value=[device]), \
         patch.object(arp_main.device_registry, "upsert_device_status") as mock_upsert, \
         patch.object(arp_main, "write_result") as mock_write:
        arp_main.run()

    mock_upsert.assert_called_once()
    args, kwargs = mock_upsert.call_args
    assert args[0] == "test-device-01"
    assert kwargs["success"] is False
    mock_write.assert_called_once_with([])


def test_collection_failure_is_logged_not_swallowed_silently():
    """Cấm silent error (8.4): lỗi collector phải đi qua upsert_device_status với success=False.

    Patch trực tiếp entry trong DEVICE_TYPE_DISPATCH (không patch attribute của module cisco_ios),
    vì dict này bind function object ngay lúc import main.py — patch attribute module sau đó
    không ảnh hưởng tới function object đã lưu trong dict.
    """
    device = _make_device("CiscoIOS")
    failing_collect = MagicMock(side_effect=RuntimeError("SNMP timeout"))

    with patch.object(arp_main.device_registry, "get_target_devices", return_value=[device]), \
         patch.object(arp_main.device_registry, "upsert_device_status") as mock_upsert, \
         patch.dict(arp_main.DEVICE_TYPE_DISPATCH, {"CiscoIOS": failing_collect}), \
         patch.object(arp_main, "write_result"):
        arp_main.run()

    mock_upsert.assert_called_once_with("test-device-01", success=False, error_message="SNMP timeout")


def test_successful_collection_marks_device_ok_and_writes_entries():
    device = _make_device("CiscoIOS")
    fake_entry = ArpEntry(
        ip_address="10.0.0.5",
        mac_address="aa:bb:cc:dd:ee:ff",
        observed_at=datetime.now(timezone.utc),
        device_id="test-device-01",
    )
    fake_collect = MagicMock(return_value=[fake_entry])

    with patch.object(arp_main.device_registry, "get_target_devices", return_value=[device]), \
         patch.object(arp_main.device_registry, "upsert_device_status") as mock_upsert, \
         patch.dict(arp_main.DEVICE_TYPE_DISPATCH, {"CiscoIOS": fake_collect}), \
         patch.object(arp_main, "write_result") as mock_write:
        arp_main.run()

    mock_upsert.assert_called_once_with("test-device-01", success=True)
    mock_write.assert_called_once_with([fake_entry])
