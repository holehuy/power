"""Lưu trữ bí mật (SNMP community string, Meraki API key) theo Phụ lục E / GUIDE.md:

"Không lưu bí mật dạng plaintext: dùng Microsoft.PowerShell.SecretManagement + SecretStore
(PowerShell) hoặc DPAPI/credential manager (Python), không hard-code trong script/config."

Cách làm: 1 file JSON chứa {device_id: base64(DPAPI-blob)}, mã hoá bằng CryptProtectData ở scope
CurrentUser — gắn với đúng tài khoản dịch vụ chuyên dụng chạy Task Scheduler (8.1: "thực thi bằng
tài khoản dịch vụ chuyên dụng"), nên chỉ tài khoản đó (trên đúng máy đó) giải mã lại được.

QA (đã thêm vào docs/open-questions.md): đây là lựa chọn triển khai theo đúng quy ước Phụ lục E,
nhưng thiết kế gốc chưa chỉ rõ ai/khi nào nạp secret ban đầu vào file này (không có "Worker khởi
tạo secret" trong 7.3) — cần quy trình vận hành riêng (đề xuất: bổ sung vào
docs/runbook/master-maintenance-checklist.md, chạy `provision_device_secret()` thủ công mỗi khi
thêm thiết bị mới vào ArpDeviceStatus).

pywin32 chỉ có trên Windows — import được trì hoãn (lazy) vào trong hàm để module này import được
bình thường trong môi trường lint/test không phải Windows (Docker dev-toolchain, xem README.md
"Limitation: production workers cannot be containerized").
"""

from __future__ import annotations

import base64
import json
import os
from pathlib import Path

_DEFAULT_STORE_PATH = "D:/ipam-worker/secrets/device-secrets.dat"


def _store_path() -> Path:
    return Path(os.environ.get("IPAM_SECRET_STORE_PATH", _DEFAULT_STORE_PATH))


def get_device_secret(device_id: str) -> str:
    """Giải mã và trả về bí mật (community SNMP / API key Meraki) của 1 thiết bị.

    Raise KeyError rõ ràng nếu thiết bị chưa được nạp secret — KHÔNG trả chuỗi rỗng âm thầm
    (8.4 cấm silent error: để lỗi này lộ ra ngoài, main.py sẽ tính là 1 lần thất bại thu thập
    của thiết bị đó thay vì gọi SNMP/API với credential rỗng).
    """
    import win32crypt  # pywin32 — chỉ có trên Windows, xem docstring module

    path = _store_path()
    if not path.exists():
        raise FileNotFoundError(f"Chưa có secret store tại {path} — chưa nạp secret cho thiết bị nào.")

    entries = json.loads(path.read_text(encoding="utf-8"))
    if device_id not in entries:
        raise KeyError(f"Thiết bị '{device_id}' chưa có secret trong {path}.")

    encrypted = base64.b64decode(entries[device_id])
    decrypted, _description = win32crypt.CryptUnprotectData(encrypted, None, None, None, 0)
    return decrypted.decode("utf-8")


def provision_device_secret(device_id: str, secret_value: str) -> None:
    """Nạp/ghi đè secret cho 1 thiết bị — chạy thủ công bởi vận hành viên khi thêm thiết bị mới
    (xem QA ở docstring module: chưa có quy trình chính thức trong thiết kế gốc)."""
    import win32crypt  # pywin32 — chỉ có trên Windows

    path = _store_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    entries = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}

    encrypted = win32crypt.CryptProtectData(secret_value.encode("utf-8"), device_id, None, None, None, 0)
    entries[device_id] = base64.b64encode(encrypted).decode("ascii")
    path.write_text(json.dumps(entries, ensure_ascii=False, indent=2), encoding="utf-8")
