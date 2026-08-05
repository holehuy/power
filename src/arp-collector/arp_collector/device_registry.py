"""Đọc danh sách thiết bị mục tiêu từ SharePoint list ArpDeviceStatus (6.9).

ArpDeviceStatus vừa là master thiết bị (team network/infrastructure duy trì bằng
chỉnh sửa trực tiếp SharePoint, 10.6) vừa là nơi Worker ghi kết quả Upsert
(LastSuccessAt, LastAttemptAt, ConsecutiveFailureCount, CurrentStatus, LastErrorMessage).
"""

from __future__ import annotations

import logging
import smtplib
from dataclasses import dataclass, replace
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage

from . import config, graph_client

logger = logging.getLogger("arp_collector.device_registry")

# 7.3: "sau đó nhắc lại mỗi 24h nếu vẫn Failed" — mốc GIỜ vận hành, KHÔNG phải ngưỡng NGÀY của
# chính sách xóa (những cái đó nằm trong thresholds.json). Không có trong thresholds.json nên
# giữ hằng số cục bộ ở đây, có trích dẫn rõ nguồn.
REMINDER_INTERVAL_HOURS = 24

_LIST_NAME = "ArpDeviceStatus"


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
    item_id: str = ""  # SharePoint item ID (khác DeviceId — business key). Dùng để PATCH lại đúng bản ghi.
    last_notified_at: datetime | None = None


# Cache trong-tiến-trình: get_target_devices() populate, upsert_device_status() tra lại để biết
# trạng thái trước đó mà không phải gọi thêm 1 lượt GET Graph API cho từng thiết bị (mỗi tiến trình
# Task Scheduler chỉ sống trong 1 chu kỳ nên không cần bền vững qua các lần chạy).
_device_cache: dict[str, ArpDevice] = {}


def _parse_target_segments(raw: object) -> list[str]:
    if raw is None:
        return []
    if isinstance(raw, list):
        return [str(v) for v in raw]
    return [str(raw)]


def _parse_datetime(raw: object) -> datetime | None:
    if not raw:
        return None
    return datetime.fromisoformat(str(raw).replace("Z", "+00:00"))


def get_target_devices() -> list[ArpDevice]:
    """Lấy toàn bộ thiết bị từ ArpDeviceStatus qua Graph API.

    Thiết bị có DeviceType chưa thiết lập hoặc ngoài định nghĩa (CiscoIOS/FortiGate/
    YamahaRTX/MerakiMX) VẪN được trả về ở đây — quyết định SKIP thu thập thuộc về main.py
    (DEVICE_TYPE_DISPATCH.get() trả None), không lọc trước ở tầng đọc dữ liệu.
    """
    raw_items = graph_client.get_list_items(_LIST_NAME)
    devices: list[ArpDevice] = []
    for fields in raw_items:
        device = ArpDevice(
            device_id=fields["DeviceId"],
            device_name=fields.get("DeviceName", ""),
            device_fqdn=fields.get("DeviceFqdn", ""),
            device_type=fields.get("DeviceType", ""),
            meraki_org_id=fields.get("MerakiOrgId") or None,
            meraki_network_id=fields.get("MerakiNetworkId") or None,
            target_segments=_parse_target_segments(fields.get("TargetSegments")),
            consecutive_failure_count=int(fields.get("ConsecutiveFailureCount") or 0),
            current_status=fields.get("CurrentStatus", "OK"),
            item_id=fields["_itemId"],
            last_notified_at=_parse_datetime(fields.get("LastNotifiedAt")),
        )
        devices.append(device)
        _device_cache[device.device_id] = device
    return devices


def compute_next_device_state(
    *,
    success: bool,
    previous_count: int,
    previous_notified_at: datetime | None,
    now: datetime,
    threshold: int,
    reminder_hours: int,
) -> tuple[int, str, str | None]:
    """Hàm thuần (không I/O) tính trạng thái kế tiếp — tách riêng để unit test không cần mock Graph API.

    Trả về (ConsecutiveFailureCount mới, CurrentStatus mới, notify_kind) với
    notify_kind in {None, "failed", "reminder"} (7.3):
      - Thành công: reset 0/OK, không thông báo kể cả khi đang Failed->OK.
      - Đạt đúng threshold (72): chuyển Failed, gửi thông báo 1 lần.
      - Vượt threshold và đã qua >= reminder_hours kể từ lần thông báo trước: nhắc lại.
    """
    if success:
        return 0, "OK", None

    new_count = previous_count + 1
    if new_count < threshold:
        return new_count, "OK", None
    if new_count == threshold:
        return new_count, "Failed", "failed"

    should_remind = previous_notified_at is None or (now - previous_notified_at) >= timedelta(hours=reminder_hours)
    return new_count, "Failed", ("reminder" if should_remind else None)


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
    device = _device_cache.get(device_id)
    if device is None:
        raise RuntimeError(
            f"upsert_device_status('{device_id}') được gọi nhưng chưa có state trước đó — "
            f"phải gọi get_target_devices() trong cùng lần chạy trước khi upsert."
        )

    threshold = config.get_threshold("arpDeviceConsecutiveFailureThreshold")
    now = datetime.now(timezone.utc)
    new_count, new_status, notify_kind = compute_next_device_state(
        success=success,
        previous_count=device.consecutive_failure_count,
        previous_notified_at=device.last_notified_at,
        now=now,
        threshold=threshold,
        reminder_hours=REMINDER_INTERVAL_HOURS,
    )

    fields: dict[str, object] = {
        "LastAttemptAt": now.isoformat(),
        "ConsecutiveFailureCount": new_count,
        "CurrentStatus": new_status,
    }
    if success:
        fields["LastSuccessAt"] = now.isoformat()
        fields["LastErrorMessage"] = ""
    else:
        fields["LastErrorMessage"] = error_message or ""
    if notify_kind is not None:
        fields["LastNotifiedAt"] = now.isoformat()

    graph_client.update_list_item(_LIST_NAME, device.item_id, fields)

    _device_cache[device_id] = replace(
        device,
        consecutive_failure_count=new_count,
        current_status=new_status,
        last_notified_at=now if notify_kind is not None else device.last_notified_at,
    )

    if notify_kind is not None:
        _send_device_alert(device, notify_kind, error_message, now)


def _send_device_alert(device: ArpDevice, notify_kind: str, error_message: str | None, now: datetime) -> None:
    """Gửi cảnh báo qua SMTP relay nội bộ (8.3: smtplib — tách khỏi luồng thông báo NotificationStage
    của PowerShell, vì đây là cảnh báo phía Python theo đúng phân công thư viện ở 8.3).

    QA: mẫu văn bản email thật (chương 13) chưa có — đã tracked ở docs/open-questions.md mục A.
    Nội dung dưới đây là placeholder hợp lý, KHÔNG phải văn bản cuối cùng.

    Không để lỗi gửi mail làm crash toàn bộ chu kỳ (8.4 "cấm silent error" nghĩa là phải LOG, không
    bắt buộc phải propagate exception ra ngoài — ở đây log đã là kênh escalate sẵn có phía Python).
    """
    subject = (
        f"[IPAM-Worker] Thiết bị ARP '{device.device_id}' chuyển Failed (72h liên tục) — Phụ lục F#12"
        if notify_kind == "failed"
        else f"[IPAM-Worker] Nhắc lại: thiết bị ARP '{device.device_id}' vẫn đang Failed — Phụ lục F#12"
    )
    body = (
        f"Thiết bị: {device.device_id} ({device.device_name}, {device.device_fqdn})\n"
        f"TargetSegments: {', '.join(device.target_segments)}\n"
        f"Thời điểm: {now.isoformat()}\n"
        f"Lỗi gần nhất: {error_message or '(không có)'}\n"
    )

    try:
        smtp_settings = config.get_smtp_settings()
        message = EmailMessage()
        message["Subject"] = subject
        message["From"] = smtp_settings.from_address
        message["To"] = smtp_settings.default_to
        message.set_content(body)
        with smtplib.SMTP(smtp_settings.relay_fqdn, timeout=30) as smtp:
            smtp.send_message(message)
        logger.info("Đã gửi alert '%s' tới %s", subject, smtp_settings.default_to)
    except Exception:
        logger.exception("Gửi alert '%s' thất bại — đã log, không retry tự động (A-4, 8.4).", subject)
