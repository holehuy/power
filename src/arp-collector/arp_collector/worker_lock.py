"""Lock file chống chạy đa instance cho TOÀN BỘ job ARP (7.3): Python (thu thập) + PowerShell
(phản ánh IPAM) chạy nối tiếp trong CÙNG 1 Task Scheduler job — lock phải bao trùm cả 2 pha,
không chỉ riêng pha Python.

Thiết kế: Python giữ lock lúc bắt đầu; PowerShell (pha CUỐI, chạy sau khi Python xuất xong JSON)
mới là bên giải phóng, bằng `Exit-WorkerLock` sẵn có trong `IpamWorkerCommon.psm1` — hàm đó chỉ
`Remove-Item` theo đường dẫn, không kiểm tra PID sở hữu, nên xoá được lock do tiến trình/ngôn ngữ
khác tạo ra. Định dạng file JSON `{"ProcessId", "AcquiredAt"}` cố ý khớp với
`Enter-WorkerLock`/`Exit-WorkerLock` phía PowerShell (8.4) để 2 phía tương thích.

QA (đã thêm vào docs/open-questions.md): "PowerShell là bên release, Python là bên acquire" là
quyết định kiến trúc suy ra lúc implement — thiết kế gốc chỉ yêu cầu chung chung "triển khai
mutex/lock file" (dòng 1155, 7.3), không chỉ rõ ai giữ/ai nhả trong kiến trúc 2 pha 1 job. Cần
Invoke-ReflectArpResults.ps1 gọi `Exit-WorkerLock -LockPath <cùng đường dẫn>` ở khối `finally`
của nó (đã implement, xem file đó) — nếu tách hạ tầng chạy 2 script thành 2 Task riêng trong
tương lai, quyết định này phải được xem lại.
"""

from __future__ import annotations

import json
import os
import time
from datetime import datetime
from pathlib import Path

_LOCK_DIR = Path(__file__).resolve().parents[3] / "logs" / "locks"
LOCK_FILE_NAME = "ArpCollectionJob.lock"  # dùng chung tên với Invoke-ReflectArpResults.ps1
_MAX_AGE_SECONDS = 60 * 60  # 1 giờ, khớp chu kỳ 7.3 — lock cũ hơn mốc này bị coi là rác (crash)


def _pid_alive(pid: int) -> bool:
    import win32api  # pywin32 — chỉ có trên Windows, xem README "Limitation"
    import win32con

    try:
        handle = win32api.OpenProcess(win32con.PROCESS_QUERY_INFORMATION, False, pid)
    except Exception:
        return False
    win32api.CloseHandle(handle)
    return True


def acquire_lock() -> Path:
    """Lấy lock cho toàn bộ job ARP (2 pha). Raise RuntimeError nếu lần chạy trước vẫn đang thực
    sự chạy (8.4: chấp nhận thiếu 1 chu kỳ, tuyệt đối không chạy chồng)."""
    _LOCK_DIR.mkdir(parents=True, exist_ok=True)
    lock_path = _LOCK_DIR / LOCK_FILE_NAME

    if lock_path.exists():
        existing = json.loads(lock_path.read_text(encoding="utf-8"))
        age_seconds = time.time() - datetime.fromisoformat(existing["AcquiredAt"]).timestamp()
        is_alive = _pid_alive(existing["ProcessId"])
        is_expired = age_seconds > _MAX_AGE_SECONDS
        if is_alive and not is_expired:
            raise RuntimeError(
                f"Job ARP đã đang chạy (PID {existing['ProcessId']}, {age_seconds:.0f}s trước). "
                f"Bỏ qua chu kỳ này (8.4: chấp nhận thiếu chu kỳ, không chạy chồng)."
            )
        # Lock rác (process đã chết, hoặc quá hạn) — tự động coi như giải phóng, ghi đè bên dưới.

    lock_path.write_text(
        json.dumps({"ProcessId": os.getpid(), "AcquiredAt": datetime.now().astimezone().isoformat()}),
        encoding="utf-8",
    )
    return lock_path
