"""Wrapper gọi Microsoft Graph API để đọc/ghi SharePoint list ArpDeviceStatus (7.3/8.2/8.3).

Đối xứng với `src/workers/common/SharePointClient.psm1` phía PowerShell, nhưng KHÔNG dùng chung
code — Python và PowerShell là 2 runtime riêng biệt trong cùng 1 Task (thiết kế 7.3/GUIDE.md).

QA (đã thêm vào docs/open-questions.md):
  msal (thư viện Python) không có API đọc chứng chỉ trực tiếp từ Windows certificate store như
  MSAL.PS (`Connect-SharePointGraph` phía PowerShell dùng CurrentUser\\My store). msal chỉ nhận
  private key ở dạng nội dung PEM + thumbprint để tự ký client assertion. Vì vậy phía Python cần
  1 file PEM riêng (IPAM_GRAPH_CERT_PEM_PATH) thay vì tham chiếu thẳng cert store — cách bảo vệ
  file này lúc nghỉ (rest) trên VM là quyết định vận hành còn treo.
"""

from __future__ import annotations

import logging
import time
from typing import Any

import msal
import requests

from . import config

logger = logging.getLogger("arp_collector.graph_client")

_GRAPH_BASE = "https://graph.microsoft.com/v1.0"
_RETRYABLE_STATUS = {408, 429, 500, 502, 503, 504}

_token_cache: dict[str, Any] = {}
_site_id_cache: dict[str, str] = {}
_list_id_cache: dict[str, str] = {}


def _acquire_app() -> msal.ConfidentialClientApplication:
    settings = config.get_graph_settings()
    with open(settings.cert_pem_path, "r", encoding="utf-8") as fh:
        private_key = fh.read()
    return msal.ConfidentialClientApplication(
        client_id=settings.client_id,
        authority=f"https://login.microsoftonline.com/{settings.tenant_id}",
        client_credential={"thumbprint": settings.cert_thumbprint, "private_key": private_key},
    )


def _get_access_token() -> str:
    """Lấy access token, tận dụng cache token nội bộ của MSAL (tự refresh khi gần hết hạn)."""
    app = _token_cache.get("app")
    if app is None:
        app = _acquire_app()
        _token_cache["app"] = app

    result = app.acquire_token_for_client(scopes=["https://graph.microsoft.com/.default"])
    if "access_token" not in result:
        raise RuntimeError(
            f"Không lấy được Graph API token: {result.get('error')} — {result.get('error_description')}"
        )
    return result["access_token"]


def _request_with_backoff(method: str, url: str, **kwargs) -> requests.Response:
    """Retry theo 8.4: tối đa graphApiBackoffMaxAttempts lần, chờ ban đầu graphApiBackoffInitialSeconds
    giây, nhân graphApiBackoffMultiplier mỗi lần. Đối tượng retry: 429/408/5xx/timeout. Ưu tiên
    header Retry-After nếu có (429). Dùng chung 1 công thức với IpamWorkerCommon.psm1 qua
    thresholds.json — không hard-code lại số vòng/độ trễ ở đây (8.4/GUIDE.md).
    """
    max_attempts = config.get_threshold("graphApiBackoffMaxAttempts")
    delay = config.get_threshold("graphApiBackoffInitialSeconds")
    multiplier = config.get_threshold("graphApiBackoffMultiplier")

    attempt = 0
    while True:
        attempt += 1
        try:
            response = requests.request(method, url, timeout=30, **kwargs)
        except requests.exceptions.Timeout:
            if attempt >= max_attempts:
                raise
            logger.warning("Graph API timeout (lần %d/%d). Chờ %ds rồi retry.", attempt, max_attempts, delay)
            time.sleep(delay)
            delay *= multiplier
            continue

        if response.status_code not in _RETRYABLE_STATUS or attempt >= max_attempts:
            return response

        retry_after = response.headers.get("Retry-After")
        wait_seconds = int(retry_after) if retry_after and retry_after.isdigit() else delay
        logger.warning(
            "Graph API trả %d (lần %d/%d). Chờ %ds rồi retry.",
            response.status_code, attempt, max_attempts, wait_seconds,
        )
        time.sleep(wait_seconds)
        delay *= multiplier


def _auth_headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {_get_access_token()}", "Content-Type": "application/json"}


def _resolve_site_id() -> str:
    settings = config.get_graph_settings()
    cache_key = f"{settings.site_host}:{settings.site_path}"
    if cache_key in _site_id_cache:
        return _site_id_cache[cache_key]

    url = f"{_GRAPH_BASE}/sites/{settings.site_host}:{settings.site_path}"
    response = _request_with_backoff("GET", url, headers=_auth_headers())
    response.raise_for_status()
    site_id = response.json()["id"]
    _site_id_cache[cache_key] = site_id
    return site_id


def _resolve_list_id(list_name: str) -> str:
    if list_name in _list_id_cache:
        return _list_id_cache[list_name]

    site_id = _resolve_site_id()
    url = f"{_GRAPH_BASE}/sites/{site_id}/lists"
    response = _request_with_backoff(
        "GET", url, headers=_auth_headers(), params={"$filter": f"displayName eq '{list_name}'", "$select": "id"}
    )
    response.raise_for_status()
    values = response.json().get("value", [])
    if not values:
        raise RuntimeError(f"Không tìm thấy SharePoint list '{list_name}' trong site đã cấu hình.")
    list_id = values[0]["id"]
    _list_id_cache[list_name] = list_id
    return list_id


def get_list_items(list_name: str, *, odata_filter: str | None = None) -> list[dict[str, Any]]:
    """Lấy toàn bộ item của 1 list (tự động phân trang theo @odata.nextLink).

    Trả về list các dict field phẳng (đã gộp thêm khoá "_itemId" = SharePoint item ID — dùng để
    PATCH lại đúng bản ghi ở update_list_item, vì `DeviceId` là business key, không phải item ID).
    """
    site_id = _resolve_site_id()
    list_id = _resolve_list_id(list_name)
    url = f"{_GRAPH_BASE}/sites/{site_id}/lists/{list_id}/items"
    params = {"expand": "fields"}
    if odata_filter:
        params["$filter"] = odata_filter

    items: list[dict[str, Any]] = []
    while url:
        response = _request_with_backoff("GET", url, headers=_auth_headers(), params=params)
        response.raise_for_status()
        payload = response.json()
        for raw_item in payload.get("value", []):
            fields = dict(raw_item.get("fields", {}))
            fields["_itemId"] = raw_item["id"]
            items.append(fields)
        url = payload.get("@odata.nextLink")
        params = None  # nextLink đã tự chứa query string
    return items


def update_list_item(list_name: str, item_id: str, fields: dict[str, Any]) -> None:
    """PATCH nhiều field trong 1 lần gọi (giảm số lần trigger phía Power Automate, đồng nhất với
    Update-SharePointListItem phía PowerShell — 6.4/6.5)."""
    site_id = _resolve_site_id()
    list_id = _resolve_list_id(list_name)
    url = f"{_GRAPH_BASE}/sites/{site_id}/lists/{list_id}/items/{item_id}/fields"
    response = _request_with_backoff("PATCH", url, headers=_auth_headers(), json=fields)
    response.raise_for_status()
