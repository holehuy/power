"""Test cho phần LOGIC THUẦN của device_registry.py (7.3) — không đụng Graph API/SMTP thật.

compute_next_device_state() tách riêng khỏi upsert_device_status() chính vì lý do này: toàn bộ
quy tắc "khi nào chuyển Failed / khi nào nhắc lại 72h-74h..." có thể test được mà không cần mock
Graph API.
"""

from __future__ import annotations

import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent / "src" / "workers" / "arp-worker"))

from arp_collector.device_registry import compute_next_device_state  # noqa: E402

THRESHOLD = 72
REMINDER_HOURS = 24
NOW = datetime(2026, 8, 5, 12, 0, 0, tzinfo=timezone.utc)


def test_success_always_resets_to_ok_even_from_failed():
    count, status, notify = compute_next_device_state(
        success=True, previous_count=200, previous_notified_at=NOW - timedelta(hours=1),
        now=NOW, threshold=THRESHOLD, reminder_hours=REMINDER_HOURS,
    )
    assert (count, status, notify) == (0, "OK", None)  # Failed->OK: không thông báo (7.3)


def test_failure_below_threshold_stays_ok_no_notify():
    count, status, notify = compute_next_device_state(
        success=False, previous_count=10, previous_notified_at=None,
        now=NOW, threshold=THRESHOLD, reminder_hours=REMINDER_HOURS,
    )
    assert (count, status, notify) == (11, "OK", None)


def test_failure_reaching_exact_threshold_transitions_to_failed_and_notifies_once():
    count, status, notify = compute_next_device_state(
        success=False, previous_count=THRESHOLD - 1, previous_notified_at=None,
        now=NOW, threshold=THRESHOLD, reminder_hours=REMINDER_HOURS,
    )
    assert (count, status, notify) == (THRESHOLD, "Failed", "failed")


def test_failure_past_threshold_within_reminder_window_does_not_renotify():
    count, status, notify = compute_next_device_state(
        success=False, previous_count=THRESHOLD + 5, previous_notified_at=NOW - timedelta(hours=1),
        now=NOW, threshold=THRESHOLD, reminder_hours=REMINDER_HOURS,
    )
    assert (count, status, notify) == (THRESHOLD + 6, "Failed", None)


def test_failure_past_threshold_after_reminder_window_notifies_again():
    count, status, notify = compute_next_device_state(
        success=False, previous_count=THRESHOLD + 5, previous_notified_at=NOW - timedelta(hours=25),
        now=NOW, threshold=THRESHOLD, reminder_hours=REMINDER_HOURS,
    )
    assert (count, status, notify) == (THRESHOLD + 6, "Failed", "reminder")


def test_failure_past_threshold_with_no_prior_notification_notifies():
    """Case biên: đã Failed từ trước (count > threshold) nhưng LastNotifiedAt trống — vd dữ liệu
    nạp ban đầu thủ công thiếu cột này. Phải coi như "chưa từng thông báo" -> nhắc ngay, không
    im lặng bỏ qua vĩnh viễn (8.4 cấm silent error)."""
    count, status, notify = compute_next_device_state(
        success=False, previous_count=THRESHOLD + 1, previous_notified_at=None,
        now=NOW, threshold=THRESHOLD, reminder_hours=REMINDER_HOURS,
    )
    assert (count, status, notify) == (THRESHOLD + 2, "Failed", "reminder")
