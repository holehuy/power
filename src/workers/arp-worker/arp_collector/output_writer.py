"""Xuất kết quả thu thập + đối chiếu ra JSON, để script PowerShell
`reflect-to-ipam/Invoke-ReflectArpResults.ps1` đọc và ghi vào IPAM (7.3: Python không
được thao tác IPAM trực tiếp, chỉ PowerShell module mới thao tác được).
"""

from __future__ import annotations

import json
from dataclasses import asdict
from pathlib import Path

from .models import ArpEntry

DEFAULT_OUTPUT_PATH = Path("D:/ipam-worker/logs/arp-collection-result.json")


def write_result(entries: list[ArpEntry], *, output_path: Path = DEFAULT_OUTPUT_PATH) -> None:
    """Ghi JSON gồm toàn bộ ArpEntry thu thập được trong chu kỳ này.

    Script phản ánh PowerShell sẽ tự phân loại theo dải IP cố định / dynamic pool dựa
    trên snapshot Segments của chính nó tại thời điểm chạy (7.3) — file JSON này chỉ
    chứa kết quả thu thập thô (IP -> MAC -> thời điểm), không phân loại trước.
    """
    payload = [
        {**asdict(entry), "observed_at": entry.observed_at.isoformat()}
        for entry in entries
    ]
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
