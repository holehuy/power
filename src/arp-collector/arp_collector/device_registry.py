"""Đọc danh sách thiết bị mục tiêu từ SharePoint list ArpDeviceStatus (6.9).

ArpDeviceStatus vừa là master thiết bị (team network/infrastructure duy trì bằng
chỉnh sửa trực tiếp SharePoint, 10.6) vừa là nơi Worker ghi kết quả Upsert
(LastSuccessAt, LastAttemptAt, ConsecutiveFailureCount, CurrentStatus, LastErrorMessage).
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class ArpDevice:
    device_id: str
    device_name: str
    device_fqdn: str
    device_type: str  # CiscoIOS | FortiGate | YamahaRTX | MerakiMX (7.3) — key điều khiển nhánh thu thập
    meraki_org_id: str | None
    meraki_network_id: str | None
    target_segments: list[str]
    consecutive_failure_count: int
    current_status: str  # OK | Failed


def get_target_devices() -> list[ArpDevice]:
    """Lấy toàn bộ thiết bị từ ArpDeviceStatus qua Graph API.

    Thiết bị có DeviceType chưa thiết lập hoặc ngoài định nghĩa (CiscoIOS/FortiGate/
    YamahaRTX/MerakiMX) sẽ bị SKIP thu thập và tính vào ConsecutiveFailureCount (7.3,
    bổ sung v1.4) — hành vi mặc định thiên về an toàn, không được âm thầm bỏ qua.
    """
    # TODO: gọi Graph API (msal client credential + cert, giống SharePointClient.psm1
    # phía PowerShell) để đọc list ArpDeviceStatus, map sang ArpDevice.
    raise NotImplementedError("TODO: implement get_target_devices()")


def upsert_device_status(
    device_id: str,
    *,
    success: bool,
    error_message: str | None = None,
) -> None:
    """Cập nhật Upsert ArpDeviceStatus sau mỗi lần xử lý thiết bị (7.3).

    - Thành công: CurrentStatus=OK, ConsecutiveFailureCount=0 (không thông báo khi Failed->OK).
    - Thất bại: tăng ConsecutiveFailureCount; khi đạt 72 (72 giờ liên tục) -> CurrentStatus=Failed
      + gửi thông báo (Phụ lục F#12) + LastNotifiedAt; sau đó nhắc lại mỗi 24h nếu vẫn Failed.
    """
    # TODO: implement PATCH ArpDeviceStatus item tương ứng device_id.
    raise NotImplementedError("TODO: implement upsert_device_status()")
