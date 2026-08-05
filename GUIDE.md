# Hướng dẫn phát triển & triển khai

Tài liệu này dành cho người trực tiếp code/build/deploy hệ thống. Xem [README.md](README.md) để có giới thiệu tổng quan dự án và setup nhanh.

## Mục lục

- [Bắt đầu từ đâu (thứ tự triển khai)](#bắt-đầu-từ-đâu-thứ-tự-triển-khai)
- [Quy ước code bắt buộc](#quy-ước-code-bắt-buộc-phụ-lục-e-thiết-kế)
- [Testing](#testing)
- [Giải thích cấu trúc source code](#giải-thích-cấu-trúc-source-code)

---

> Yêu cầu môi trường (bảng phiên bản công cụ), dev-toolchain qua Docker/Docker Compose (`make build`/`make test`/`make shell`...), và giới hạn không container hoá được của IPAM/DHCP/DNS: xem mục **[Environment Setup](README.md#environment-setup)** trong README.md — không lặp lại ở đây để tránh 2 nguồn lệch nhau.

## Bắt đầu từ đâu (thứ tự triển khai)

1. Xử lý các phụ thuộc chặn đường phía khách hàng trước (Phụ lục C + RACI Phụ lục G) — xem `docs/open-questions.md`.
2. Provision hạ tầng: `infra/bicep/main.bicep` → chạy `infra/scripts/bootstrap-vm.ps1` để join domain, cài tính năng IPAM, Python, đăng ký Task Scheduler. Hướng dẫn đầy đủ (prerequisites, lệnh `az deployment group create`, tham số cần truyền, cách xác nhận thành công): xem mục **[Infrastructure Deployment](README.md#infrastructure-deployment)** trong README.md.
   - **Việc cần làm trước khi deploy**: xác nhận với khách hàng resource group đích (`<target-rg>`) là dùng chung resource group hiện có hay tạo mới riêng cho hệ thống này. Nếu dùng chung, đề nghị khách hàng chỉ định rõ tên/ID resource group đó (đã thêm vào `docs/open-questions.md`).
   - **Việc cần làm trước khi join domain**: thiết kế không chỉ rõ ai thực hiện join domain AD nội bộ cho VM. Xác nhận với khách hàng: vendor sẽ chạy thao tác join, nhưng khách hàng cần cấp trước tài khoản có quyền join domain và xác nhận OU/naming policy cho computer object nếu có (đã thêm vào `docs/open-questions.md`).
3. Dựng 7 SharePoint list: `sharepoint/Provision-SharePointLists.ps1` (đọc schema JSON trong `sharepoint/schema/`).
4. Nạp dữ liệu ban đầu bằng `tools/initial-data-loader/` (Segments, ArpDeviceStatus — dữ liệu do khách hàng cung cấp theo Phụ lục C.6/G).
5. Deploy 4 Worker trong `src/workers/` + Worker ARP trong `src/arp-collector/` lên Azure VM, đăng ký lịch chạy đúng tần suất ghi trong header từng script.
6. Import Power Platform solution trong `powerplatform/` vào môi trường Power Apps/Automate.

## Quy ước code bắt buộc (Phụ lục E thiết kế)

- **Cấm silent error**: mọi exception phải được log (Windows Event Log `IPAM-Worker` + file log) và đi tới một luồng thông báo (người đăng ký hoặc `nkis-network@nkc.co.jp`).
- **Không lưu bí mật dạng plaintext**: dùng `Microsoft.PowerShell.SecretManagement` + `SecretStore` (PowerShell) hoặc DPAPI/credential manager (Python), không hard-code trong script/config.
- **Idempotency bắt buộc**: mọi Worker phải chịu được crash/chạy lại giữa chừng mà không gây tác dụng phụ trùng lặp (xem `IpamWorkerCommon.psm1`).
- **Không hard-code ngưỡng ngày**: 30/90/180/365 ngày, Cooldown 30 ngày, v.v. đọc từ `src/config/thresholds.json`, có guard tối thiểu 7 ngày.
- PowerShell: tuân thủ PSScriptAnalyzer default rules. Python: `venv` + `requirements.txt` cố định version.

## Testing

Qua Docker (khuyến nghị, xem mục Docker ở trên): `make test-ps test-py`, hoặc chạy native nếu đã cài sẵn công cụ:

```powershell
Invoke-Pester ./tests/powershell -CI
```
```bash
pytest tests/python
```

---

## Giải thích cấu trúc source code

### `docs/`
Tài liệu, không phải code chạy được, nhưng là nguồn sự thật cho mọi quyết định implement. `docs/design/` giữ nguyên văn bản thiết kế v1.4. `docs/runbook/` là nơi soạn tài liệu quy trình vận hành/khôi phục/bảo trì master — đây là **deliverable bắt buộc** của vendor theo thiết kế (10.5, 10.6, 10.7), không phải tài liệu nội bộ tùy chọn. `docs/open-questions.md` theo dõi 8 giá trị còn treo từ v1.3 và các mục Phụ lục C/RACI cần khách hàng xác nhận — nên cập nhật liên tục trong suốt dự án, không chỉ đọc một lần.

### `infra/`
Infrastructure-as-Code cho phần hạ tầng vendor chịu trách nhiệm dựng (theo RACI Phụ lục G: "Azure VM tạo mới ~ cấu hình OS, kích hoạt IPAM, đăng ký scheduler" là việc của vendor; subscription/VNet là việc của khách hàng nên **không** có trong `infra/bicep` — chỉ tham chiếu VNet có sẵn qua parameter). `modules/vm.bicep` dựng đúng spec 8.1 (4vCPU/16GB, Windows Server 2022, data disk riêng cho script+log). `modules/backup-vault.bicep` dựng Recovery Services vault riêng cho hệ thống này (10.5). `modules/monitor-heartbeat.bicep` là Azure Monitor heartbeat alert — cơ chế duy nhất phát hiện khi chính VM bị dừng, vì script giám sát chạy trên VM đó không tự phát hiện được việc VM ngừng chạy (10.4). `infra/scripts/bootstrap-vm.ps1` chạy sau khi VM lên: join domain, cài Windows Feature IPAM, cài Python 3.11, tạo custom Event Log "IPAM-Worker", đăng ký 5 Task Scheduler job.

### `src/workers/` — trái tim của hệ thống
Mỗi Worker là một script PowerShell độc lập, ứng với đúng 1 hàng trong bảng 4.2 của thiết kế:

- `common/` — 3 module dùng chung cho cả 4 Worker, tách riêng để logic hạ tầng (lock, retry, log, gọi SharePoint) không lặp lại ở từng Worker:
  - `IpamWorkerCommon.psm1`: cơ chế mutex/lock-file chống chạy đa instance + named mutex theo từng IP để Worker tự động xóa và Worker ARP không đụng cùng entry (8.4), retry exponential backoff cho Graph API (2s/4s/8s, đối tượng 429/408/5xx), hàm tính "số ngày đã trôi qua" có trừ `SkippedDays` (quy ước chuẩn ở 6.8-2 — **mọi nơi tính hạn xóa phải gọi qua hàm này**, không tự tính lại để tránh lệch công thức).
  - `SharePointClient.psm1`: wrapper gọi Graph API đọc/ghi 7 SharePoint list, tách riêng để đổi cách xác thực (chứng chỉ Entra ID app) không phải sửa từng Worker.
  - `NotificationClient.psm1`: gửi alert qua SMTP relay nội bộ tới `nkis-network@nkc.co.jp`, có sẵn helper chống gửi trùng (guard column pattern dùng chung cho toàn bộ 21 loại thông báo ở Phụ lục F).
- `allocation-worker/` — Worker cấp phát IP (7.1), chạy mỗi 5 phút. Đây là luồng phức tạp nhất: xử lý theo từng dòng chi tiết (không phải theo cha), skip segment đang `RangeChangePending`, tối đa 3 ứng viên IP trống, rollback IPAM khi lỗi DNS, tổng hợp Status cha ở đầu mỗi chu kỳ (tự phục hồi nếu crash giữa chừng).
- `segment-sync-worker/` — đồng bộ Segment (7.2), chạy mỗi 30 phút (:15/:45). Phụ thuộc dữ liệu output của worker này là **điều kiện tiên quyết** để `allocation-worker` chạy đúng — nên build/test worker này trước.
- `auto-deletion-worker/` — tự động xóa (7.4), chạy hằng ngày 02:00 JST. Rủi ro cao nhất trong cả hệ thống (xóa nhầm IP đang dùng), nên đây là worker cuối cùng nên build và cần bộ test kỹ nhất — logic bậc thang ngày, sub-flow Cooldown +31 ngày, snapshot đầu-ca-quét, bộ đệm khi gỡ skip đều nằm ở đây.
- `monitoring-script/` — chạy hằng ngày 07:00 JST, quyền chỉ đọc (9.1). Chỉ phát hiện + báo cáo, **cố tình không tự động sửa/gửi lại** (quyết định A-4 v1.4) để tránh che giấu lỗi gốc.

### `src/arp-collector/`
Worker thu thập ARP viết bằng Python vì cần thư viện SNMP/Meraki SDK đa vendor, chạy mỗi giờ. Tách thành 2 phần đúng như thiết kế 7.3 mô tả: `arp_collector/` (Python) chỉ **thu thập + đối chiếu**, xuất kết quả ra JSON; `reflect-to-ipam/Invoke-ReflectArpResults.ps1` (PowerShell) mới là phần **ghi vào IPAM**, vì IPAM chỉ thao tác được qua PowerShell module — hai script này chạy nối tiếp trong cùng một Task. `collectors/` chứa 1 file/vendor (CiscoIOS, FortiGate, YamahaRTX, MerakiMX) ứng với cột `ArpDeviceStatus.DeviceType` — thêm vendor mới chỉ cần thêm 1 file ở đây, không sửa `main.py`.

### `src/config/`
`thresholds.json` giữ toàn bộ ngưỡng ngày (30/90/180/365, Cooldown 30, bộ đệm gỡ skip...) dưới dạng tham số ngoài, đúng yêu cầu "Externalize ngưỡng ngày" ở 8.4 — mục đích để nghiệm thu có thể rút ngắn ngưỡng khi test hành vi phụ thuộc thời gian, và để chuyển đổi ngưỡng "kéo dài ban đầu" (90 ngày, theo 10.2/A-3) sang ngưỡng định thường (30 ngày) mà không cần sửa code.

### `powerplatform/`
Chứa Power Apps canvas app và các Power Automate flow dưới dạng **Power Platform Solution** (unpack bằng `pac solution unpack` thành file text để review/diff trong git — file `.msapp` gốc là binary, không diff được). README riêng trong thư mục này hướng dẫn pack/unpack/export/import.

### `sharepoint/`
`schema/*.schema.json` — định nghĩa cột của cả 7 list, dịch trực tiếp từ chương 6 thiết kế (bao gồm 7 cột bổ sung + 1 cột di chuyển của v1.4: `CoverageStatus`, `CoverageCheckedAt`, `CoverageNotifiedAt`, `RangeChangePending`, `LastSkipDate`, `SkippedDays`, và `DnsServers` dời từ bảng lịch sử sửa đổi vào đúng vị trí). `Provision-SharePointLists.ps1` dùng PnP.PowerShell đọc các schema này để tạo list + cột index (`IPRequests.Status`/`RequesterUpn`, `IPRequestItems.Status`/`ParentItemId`/`AssignedIp`, `Segments.SiteCode`/`RegionCode` — bắt buộc để Power Apps delegation hoạt động đúng, thiếu cột index sẽ khiến query bị giới hạn 2000 dòng âm thầm sai kết quả).

### `tools/initial-data-loader/`
Script nạp dữ liệu ban đầu cho `Segments` (khoảng 1000 record) và `ArpDeviceStatus` (danh sách thiết bị NW theo Phụ lục C.6) — đây chính là "CSV tool" được nhắc trong RACI Phụ lục G, việc **nhập liệu** là trách nhiệm vendor nhưng **tạo danh sách nguồn** là trách nhiệm khách hàng, nên input của tool này luôn là file CSV nhận từ khách hàng, không tự sinh dữ liệu.

### `tests/`
`tests/powershell/` dùng Pester, tách theo từng Worker. Ưu tiên viết test cho các nhánh dễ sai nhất trước: tính dải IP cố định (7.2, công thức từng bị sửa ngược ở v1.1), tổng hợp Status cha (7.1), tính số ngày đã trôi qua có trừ SkippedDays (6.8-2), predicate hết hạn Cooldown +31 ngày (7.4). `tests/python/` dùng pytest cho từng collector — nên mock response SNMP/Meraki API, không gọi thiết bị thật trong CI.
