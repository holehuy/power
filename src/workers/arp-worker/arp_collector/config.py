"""Cấu hình dùng chung cho ARP Collector (7.3/8.2/8.3).

Mọi giá trị nhạy cảm/đặc thù môi trường lấy từ biến môi trường (đặt tên cùng tiền tố
`IPAM_` như phía PowerShell — xem NotificationClient.psm1) hoặc từ `src/config/thresholds.json`
(ngưỡng dùng chung nhiều Worker, KHÔNG hard-code lại ở đây — 8.4/GUIDE.md "Quy ước code bắt buộc").

QA — giá trị còn treo, cần xác nhận trước khi build/test tích hợp thật (xem docs/open-questions.md):
  - IPAM_GRAPH_TENANT_ID / IPAM_GRAPH_CLIENT_ID / IPAM_GRAPH_CERT_THUMBPRINT: chỉ có thật sau khi
    đăng ký ứng dụng Entra ID + admin consent (RACI, Phụ lục G — việc của khách hàng).
  - IPAM_GRAPH_CERT_PEM_PATH: xem ghi chú trong graph_client.py — msal (Python) KHÔNG đọc được
    thẳng chứng chỉ từ Windows cert store như MSAL.PS bên PowerShell, nên cần đường dẫn private key
    riêng. Cách bảo vệ file này khi ở trạng thái nghỉ (rest) là mục còn treo, đã thêm vào
    docs/open-questions.md.
  - IPAM_SHAREPOINT_SITE_HOST / IPAM_SHAREPOINT_SITE_PATH: hostname + đường dẫn site SharePoint
    thật, chỉ biết được sau khi khách hàng cấp site (RACI Phụ lục G).
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

_THRESHOLDS_PATH = Path(__file__).resolve().parents[2] / "config" / "thresholds.json"


@lru_cache(maxsize=1)
def _load_thresholds() -> dict:
    return json.loads(_THRESHOLDS_PATH.read_text(encoding="utf-8"))


def get_threshold(name: str) -> int:
    """Đọc 1 giá trị ngưỡng từ src/config/thresholds.json (dùng chung với các Worker PowerShell).

    Không cache riêng theo tiến trình dài hạn — mỗi lần chạy Task Scheduler là 1 process mới nên
    lru_cache ở mức module là đủ (không cần lo giá trị bị "đóng băng" giữa các lần chạy).
    """
    config = _load_thresholds()
    if name not in config or config[name] is None:
        raise KeyError(f"Không tìm thấy threshold '{name}' trong {_THRESHOLDS_PATH}")
    return config[name]


@dataclass(frozen=True)
class GraphSettings:
    tenant_id: str
    client_id: str
    cert_thumbprint: str
    cert_pem_path: str
    site_host: str
    site_path: str


@dataclass(frozen=True)
class SmtpSettings:
    relay_fqdn: str
    from_address: str
    default_to: str = "nkis-network@nkc.co.jp"


def _require_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(
            f"Biến môi trường '{name}' chưa được cấu hình. Đây là giá trị đặc thù môi trường/khách "
            f"hàng (xem docs/open-questions.md) — không có giá trị mặc định hợp lý để dùng thay."
        )
    return value


def get_graph_settings() -> GraphSettings:
    return GraphSettings(
        tenant_id=_require_env("IPAM_GRAPH_TENANT_ID"),
        client_id=_require_env("IPAM_GRAPH_CLIENT_ID"),
        cert_thumbprint=_require_env("IPAM_GRAPH_CERT_THUMBPRINT"),
        cert_pem_path=_require_env("IPAM_GRAPH_CERT_PEM_PATH"),
        site_host=_require_env("IPAM_SHAREPOINT_SITE_HOST"),
        site_path=_require_env("IPAM_SHAREPOINT_SITE_PATH"),
    )


def get_smtp_settings() -> SmtpSettings:
    return SmtpSettings(
        relay_fqdn=_require_env("IPAM_SMTP_RELAY_FQDN"),
        from_address=_require_env("IPAM_WORKER_MAIL_FROM"),
    )
