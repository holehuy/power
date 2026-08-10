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
5. Deploy `src/workers/` (4 Worker, kể cả `arp-worker/`), `src/monitoring/` (script giám sát chỉ đọc, không phải Worker thứ 5), và `src/common/` (hạ tầng dùng chung cả 2 bên) lên Azure VM, đăng ký lịch chạy đúng tần suất ghi trong header từng script.
6. Import Power Platform solution trong `powerplatform/` vào môi trường Power Apps/Automate.

## Quy ước code bắt buộc (Phụ lục E thiết kế)

- **Cấm silent error**: mọi exception phải được log (Windows Event Log `IPAM-Worker` + file log) và đi tới một luồng thông báo (người đăng ký hoặc `nkis-network@nkc.co.jp`).
- **Không lưu bí mật dạng plaintext**: dùng `Microsoft.PowerShell.SecretManagement` + `SecretStore` (PowerShell) hoặc DPAPI/credential manager (Python), không hard-code trong script/config.
- **Idempotency bắt buộc**: mọi Worker phải chịu được crash/chạy lại giữa chừng mà không gây tác dụng phụ trùng lặp (xem `Common.psm1`).
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

### `src/common/` — hạ tầng dùng chung (KHÔNG lồng trong `src/workers/` — dùng bởi cả `workers/` LẪN `monitoring/`, 2 consumer thật, nên tách ra ngang hàng thay vì nằm trong 1 trong 2 bên)
  - `Common.psm1` (đổi tên từ `IpamWorkerCommon.psm1` — nội dung chưa bao giờ riêng cho IPAM): cơ chế mutex/lock-file chống chạy đa instance + named mutex theo từng IP để Worker tự động xóa và Worker ARP không đụng cùng entry (8.4), retry exponential backoff cho Graph API (2s/4s/8s, đối tượng 429/408/5xx), hàm tính "số ngày đã trôi qua" có trừ `SkippedDays` (quy ước chuẩn ở 6.8-2 — **mọi nơi tính hạn xóa phải gọi qua hàm này**, không tự tính lại để tránh lệch công thức), và `Write-WorkerLog` — ghi Event Log + file log, LogLevel (`Debug`/`Information`/`Warning`/`Error`) cấu hình qua biến môi trường `IPAM_WORKER_LOG_LEVEL` hoặc `Set-WorkerLogLevel`; `Error` luôn được ghi bất kể ngưỡng (không vi phạm "cấm silent error" 8.4 dù cấu hình sai), `Debug` chỉ ghi file log (Event Log không có mức Debug).

    `Write-InfoLog`/`Write-WarningLog`/`Write-ErrorLog`/`Write-DebugLog` (mới — KHÔNG đặt `Write-Info`/`Write-Warning`/`Write-Error`: 2 tên sau trùng cmdlet có sẵn của PowerShell, sẽ che mất cmdlet gốc trong scope import module) nhận **`-Code` HOẶC `-Message`** (ít nhất 1 trong 2 — ưu tiên `-Code` nếu truyền cả 2). **Đây là cách DUY NHẤT nên dùng để ghi log** — không còn chỗ nào trong `src/workers/`/`src/monitoring/`/chính `src/common/` gọi thẳng `Write-WorkerLog` nữa (đã migrate hết, kể cả `SharePointClient.psm1`/`NotificationClient.psm1`); `Write-WorkerLog` giờ chỉ còn là engine nội bộ mà 4 hàm này gọi xuống, không phải điểm vào cho code nghiệp vụ.
    - `-Code` (dạng `<PREFIX>-<Worker-ID>-<XXXX>`, vd `ERR-ALLOC-0001`): tra message trong đúng catalog theo `PREFIX` — `src/config/log-info-messages.json` / `log-warning-messages.json` / `log-error-messages.json` / `log-debug-messages.json` (4 file TÁCH RIÊNG theo level, không dùng chung 1 file), thay `{{Token}}` bằng `-Parameters @{...}`; mỗi hàm validate `PREFIX` phải đúng level của nó (`INFO-`/`WARN-`/`ERR-`/`DEBUG-`) — gọi sai hàm thì throw ngay, không thể lệch code/level.
    - `-Message` (chuỗi tự do, không qua catalog): dùng khi không cần chuẩn hoá qua JSON — đa số message hiện tại (ngoài vài message ví dụ đã có Code) đi đường này.
    - **Level KHÔNG lưu trong JSON** — quyết định bởi việc gọi hàm nào, không phải field trong catalog.
    - **EventId**: 1 Worker-ID dùng CHUNG 1 EventId mặc định duy nhất (không phân theo Level/Seq — đơn giản hoá): `ARP=1000` (3 EventId `1001`/`1002`/`1003` của ARP theo thiết kế gốc 7.3 dùng qua `-EventId` tay, không qua mặc định này), `ALLOC=2000`, `SYNC=3000`, `DEL=4000`, `MON=5000`, `SHAREPOINT=1800`, `NOTIF=1900` (bảng `$script:WorkerIdEventIdBase` — **7** Worker-ID, không chỉ 5, vì `SharePointClient.psm1`/`NotificationClient.psm1` cũng đăng ký riêng — xem ngay dưới). Muốn EventId cụ thể khác thì truyền tay `-EventId`.
    - **Worker-ID lấy từ đâu**: dùng `-Code` thì Worker-ID nằm sẵn trong chuỗi Code (vd `ERR-ALLOC-0001` → `ALLOC`), tự suy EventId, không phụ thuộc gì thêm — đây là lý do `SharePointClient.psm1`/`NotificationClient.psm1` (hạ tầng dùng chung, không thuộc về 1 Worker cụ thể nào đang chạy) cũng dùng `-Code` (`INFO-SHAREPOINT-0001`, `INFO-NOTIF-0001`, `ERR-NOTIF-0001`) thay vì `-Message` + `-EventId` tay: tránh vừa phải gõ số tay, vừa tránh phụ thuộc `Get-CurrentWorkerId` ambient (quan trọng nhất ở nhánh log lỗi — nếu chính việc BÁO LỖI gửi mail lại phụ thuộc ambient Worker-ID của Worker đang gọi vào, 1 lần `Set-CurrentWorkerId` bị thiếu/gọi sai ở đâu đó có thể khiến việc báo lỗi cũng throw theo, không chấp nhận được — 8.4). Dùng `-Message` (không có Code) thì PHẢI gọi `Set-CurrentWorkerId -WorkerId 'ALLOC'` 1 lần ở đầu script (ngay sau các `Import-Module`, **trước** mọi `Write-*Log` khác) — cả 4 Worker (`allocation-worker`, `segment-sync-worker`, `auto-deletion-worker`, `arp-worker/reflect-to-ipam`) LẪN `src/monitoring` (dù không phải Worker chính thức, vẫn cần đăng ký `MON` để tự suy EventId) đã gọi đúng vị trí này; thiếu cả `Set-CurrentWorkerId` lẫn `-EventId` thì throw (không âm thầm ghi sai EventId).
    - `-IncludeCodePrefix` (mặc định BẬT, chỉ áp dụng khi dùng `-Code`): tự thêm `[Code] ` vào đầu message ghi ra (vd `[ERR-ALLOC-0001] Lỗi xử lý...`) để nhìn log biết ngay message nào không cần tra EventId — tắt bằng `-IncludeCodePrefix:$false`.
    - Windows Event Log **EntryType** (Information/Warning/Error) tự map từ Level ở `Write-WorkerLog` bên dưới — có sẵn từ đầu, không phải phần mới. `Write-DebugLog` không ghi Event Log (chỉ file log — kế thừa hành vi Debug của `Write-WorkerLog`).
    - Định danh CHÍNH XÁC theo từng message luôn là chuỗi Code/nội dung Message, không phải EventId — EventId giờ chỉ lọc thô theo Worker-ID trong Event Viewer.

    `Expand-MessageTemplate` (thay `{{Token}}`, throw nếu thiếu param bắt buộc — 8.4) dùng chung bởi cả 4 hàm trên LẪN `NotificationClient.psm1` (`Send-TemplatedAlert`) — không cài lại 2 nơi.
  - `SharePointClient.psm1`: wrapper gọi Graph API đọc/ghi 7 SharePoint list, tách riêng để đổi cách xác thực (chứng chỉ Entra ID app) không phải sửa từng Worker.
  - `NotificationClient.psm1`: gửi alert qua SMTP relay nội bộ tới `nkis-network@nkc.co.jp`, có sẵn helper chống gửi trùng (guard column pattern dùng chung cho toàn bộ 21 loại thông báo ở Phụ lục F). `Send-InternalAlert` gửi thẳng Subject/Body dựng sẵn (giữ nguyên, dùng khi nội dung động phức tạp hơn 1 template cố định). `Send-TemplatedAlert` (mới) dựng Subject/Body từ file trong `templates/*.txt|*.html` (đặt tên theo ID Phụ lục F, vd `F14-cooldown-restore.txt`) + thay `{{Token}}` bằng `-Parameters @{...}` — tách nội dung mail khỏi code, để khi khách hàng cung cấp mẫu thật (chương 13, còn treo — `docs/open-questions.md` mục A) chỉ cần thêm/sửa file template, không sửa Worker. `.html` → gửi `-BodyAsHtml`, thiếu param bắt buộc trong template → throw (không âm thầm gửi mail còn sót literal `{{Token}}`, 8.4).

### `src/workers/` — trái tim của hệ thống
4 Worker chính thức đúng 4 hàng trong bảng 4.2 của thiết kế (`simple_design.md:295-323`) — tất cả đều GHI dữ liệu (IPAM/DNS/SharePoint):

- `allocation-worker/` — Worker cấp phát IP (7.1), chạy mỗi 5 phút. Đây là luồng phức tạp nhất: xử lý theo từng dòng chi tiết (không phải theo cha), skip segment đang `RangeChangePending`, tối đa 3 ứng viên IP trống, rollback IPAM khi lỗi DNS, tổng hợp Status cha ở đầu mỗi chu kỳ (tự phục hồi nếu crash giữa chừng).
- `segment-sync-worker/` — đồng bộ Segment (7.2), chạy mỗi 30 phút (:15/:45). Phụ thuộc dữ liệu output của worker này là **điều kiện tiên quyết** để `allocation-worker` chạy đúng — nên build/test worker này trước.
- `auto-deletion-worker/` — tự động xóa (7.4), chạy hằng ngày 02:00 JST. Rủi ro cao nhất trong cả hệ thống (xóa nhầm IP đang dùng), nên đây là worker cuối cùng nên build và cần bộ test kỹ nhất — logic bậc thang ngày, sub-flow Cooldown +31 ngày, snapshot đầu-ca-quét, bộ đệm khi gỡ skip đều nằm ở đây.
- `arp-worker/` — worker thứ 4 trong bảng chính thức (7.3), chạy mỗi giờ. Tách thành 2 phần theo đúng thiết kế: `arp_collector/` (Python — tên mô tả đúng việc nó làm: chỉ **thu thập + đối chiếu**, xuất kết quả ra JSON, không đụng IPAM) và `reflect-to-ipam/Invoke-ReflectArpResults.ps1` (PowerShell — phần DUY NHẤT **ghi vào IPAM**, vì IPAM chỉ thao tác được qua PowerShell module); hai script này chạy nối tiếp trong cùng một Task Scheduler job. Có `venv`/`requirements.txt`/`pytest` riêng (khác `common/` PowerShell) vì là ngôn ngữ khác — đây là lý do duy nhất khiến nó có sub-structure khác 3 worker kia, không phải vì nó "không phải worker". `collectors/` chứa 1 file/vendor (CiscoIOS, FortiGate, YamahaRTX, MerakiMX) ứng với cột `ArpDeviceStatus.DeviceType` — thêm vendor mới chỉ cần thêm 1 file ở đây, không sửa `main.py`.

### `src/monitoring/` — KHÔNG nằm trong `src/workers/` (cố ý)
Thiết kế gốc gọi đây là **"監視スクリプト" (Monitoring "Script")** — không một lần nào gọi là "…Worker" trong toàn bộ `simple_design.md`, khác hẳn 4 thành phần trên (đều có "Worker" trong tên tiếng Nhật). Không chỉ tên gọi khác: **bảng 4.2 chính thức không có dòng nào cho nó** — nó chỉ xuất hiện ở 1 dòng ghi chú "※" riêng ngay dưới bảng (`simple_design.md:327`, lịch chạy 07:00 JST), tách hẳn khỏi 4 hàng Worker chính thức. Lý do kiến trúc: đây là thành phần **DUY NHẤT chỉ đọc, không bao giờ ghi** — §9.1 (`simple_design.md:1471`) ghi rõ *"監視スクリプトへの書込権限は付与しない"* (không cấp quyền ghi), §10.4 (`simple_design.md:1547`) xác nhận lại *"監視スクリプトのSharePoint権限は読み取りのみである"* (quyền SharePoint chỉ đọc). Chỉ phát hiện + báo cáo, **cố tình không tự động sửa/gửi lại** (quyết định A-4 v1.4) để tránh che giấu lỗi gốc. Đặt `src/monitoring/` ngang hàng `src/workers/` (không lồng bên trong) để phản ánh đúng: nó không phải Worker thứ 5, mà là 1 watchdog riêng biệt quan sát cả 4 Worker + `common/`.

`Invoke-MonitoringCheck.ps1` chạy hằng ngày 07:00 JST, quyền chỉ đọc (9.1), gọi `Set-CurrentWorkerId -WorkerId 'MON'` như 4 Worker kia để `Write-InfoLog -Message` tự suy đúng EventId.

### `src/config/`
`thresholds.json` giữ toàn bộ ngưỡng ngày (30/90/180/365, Cooldown 30, bộ đệm gỡ skip...) dưới dạng tham số ngoài, đúng yêu cầu "Externalize ngưỡng ngày" ở 8.4 — mục đích để nghiệm thu có thể rút ngắn ngưỡng khi test hành vi phụ thuộc thời gian, và để chuyển đổi ngưỡng "kéo dài ban đầu" (90 ngày, theo 10.2/A-3) sang ngưỡng định thường (30 ngày) mà không cần sửa code.

`log-info-messages.json` / `log-warning-messages.json` / `log-error-messages.json` / `log-debug-messages.json` — 4 catalog TÁCH RIÊNG theo level (đọc bởi `Write-InfoLog`/`-WarningLog`/`-ErrorLog`/`-DebugLog` tương ứng, `Common.psm1`, tự chọn đúng file theo `PREFIX` của Code — xem `$script:LogCatalogFileByPrefix`): mỗi file `{ "<Code>": "message template, có thể chứa {{Token}}" }` — chỉ message, KHÔNG có field level (Level xác định bởi chính tên file/hàm gọi, không cần lưu lại trong JSON). Format Code: `<PREFIX>-<Worker-ID>-<XXXX>` — `PREFIX` = `INFO`/`WARN`/`ERR`/`DEBUG` (khớp file + hàm gọi), `Worker-ID` viết tắt theo worker/module (`ALLOC`, `SYNC`, `DEL`, `MON`, `ARP`, `SHAREPOINT`, `NOTIF` — đăng ký trong `$script:WorkerIdEventIdBase` của `Common.psm1`), `XXXX` là số thứ tự tự chọn (không ràng buộc phải liên tục — chỉ cần không trùng trong cùng Worker+PREFIX). `log-warning-messages.json` và `log-debug-messages.json` hiện là `{}` (chưa có message nào theo code ở 2 mức này — vẫn tạo sẵn file rỗng để lỗi báo đúng "code không tồn tại" thay vì "file không tồn tại" khi có người dùng `-Code` trước khi ai đó thêm entry).

Quy ước trong `log-info-messages.json`/`log-error-messages.json`: key `"_comment_<WORKER-ID>": "..."` xen giữa các nhóm — JSON không có cú pháp comment thật, đây là comment giả (chuỗi bình thường, không parse được thành gì) chỉ để mắt người đọc dễ tách từng Worker/module khi mở file; `Get-LogMessageTemplate` không bao giờ tra tới các key này (Code thật luôn khớp `LogCodePattern`, khác hẳn format `_comment_*`).

**Mọi Worker-ID đều có đủ cặp Code `-0001` (bắt đầu) / `-0002` (kết thúc)** trong `log-info-messages.json`, kể cả 2 module hạ tầng dùng chung không chạy theo chu kỳ Task Scheduler:
- 5 script theo chu kỳ (`ALLOC`/`SYNC`/`DEL`/`ARP`/`MON`): `-0001` bắt đầu chu kỳ, `-0002` kết thúc chu kỳ. `ARP` trước đây chỉ có log kết thúc, không có log bắt đầu — đã bổ sung `INFO-ARP-0001`.
- `SHAREPOINT`/`NOTIF` (theo từng lần gọi hàm, không theo chu kỳ): `-0001` = bắt đầu gọi (`Connect-SharePointGraph`/`Send-InternalAlert`), `-0002` = kết thúc thành công. Riêng `NOTIF` có thêm nhánh kết thúc thất bại — dùng `ERR-NOTIF-0001` (khác file, mức Error) thay vì 1 `INFO-NOTIF-XXXX` khác, vì bản chất là 2 KẾT QUẢ khác nhau của cùng 1 lần "kết thúc", không phải 2 sự kiện khác nhau.

**EventId mặc định = 1 số CỐ ĐỊNH cho cả 1 Worker** (không phân theo Level/Seq — đơn giản hoá theo yêu cầu thực tế, không cần độ chi tiết cao hơn): `ARP=1000`, `ALLOC=2000`, `SYNC=3000`, `DEL=4000`, `MON=5000`. Riêng ARP: thiết kế gốc 7.3 đã quy định sẵn `1001`/`1002`/`1003` cho 3 kết quả execution cụ thể (thành công/thất bại một phần/thất bại toàn bộ) — 3 số đó truyền tay qua `-EventId`, không qua bảng mặc định này. Định danh CHÍNH XÁC theo từng message luôn là chuỗi Code hoặc nội dung Message, không phải EventId — EventId giờ chỉ để lọc thô theo Worker trong Event Viewer.

Hiện mới migrate 3 message của `allocation-worker` sang `-Code` làm ví dụ — các `Write-WorkerLog -Message "..."` freeform còn lại trong 4 worker khác vẫn hợp lệ (hoặc có thể đổi sang `Write-InfoLog/-WarningLog/-ErrorLog -Message "..."` để đồng bộ cách gọi mà không cần thêm entry vào catalog), không bắt buộc migrate hết.

### `powerplatform/`
Chứa Power Apps canvas app và các Power Automate flow dưới dạng **Power Platform Solution** (unpack bằng `pac solution unpack` thành file text để review/diff trong git — file `.msapp` gốc là binary, không diff được). README riêng trong thư mục này hướng dẫn pack/unpack/export/import.

### `sharepoint/`
`schema/*.schema.json` — định nghĩa cột của cả 7 list, dịch trực tiếp từ chương 6 thiết kế (bao gồm 7 cột bổ sung + 1 cột di chuyển của v1.4: `CoverageStatus`, `CoverageCheckedAt`, `CoverageNotifiedAt`, `RangeChangePending`, `LastSkipDate`, `SkippedDays`, và `DnsServers` dời từ bảng lịch sử sửa đổi vào đúng vị trí). `Provision-SharePointLists.ps1` dùng PnP.PowerShell đọc các schema này để tạo list + cột index (`IPRequests.Status`/`RequesterUpn`, `IPRequestItems.Status`/`ParentItemId`/`AssignedIp`, `Segments.SiteCode`/`RegionCode` — bắt buộc để Power Apps delegation hoạt động đúng, thiếu cột index sẽ khiến query bị giới hạn 2000 dòng âm thầm sai kết quả).

### `tools/initial-data-loader/`
Script nạp dữ liệu ban đầu cho `Segments` (khoảng 1000 record) và `ArpDeviceStatus` (danh sách thiết bị NW theo Phụ lục C.6) — đây chính là "CSV tool" được nhắc trong RACI Phụ lục G, việc **nhập liệu** là trách nhiệm vendor nhưng **tạo danh sách nguồn** là trách nhiệm khách hàng, nên input của tool này luôn là file CSV nhận từ khách hàng, không tự sinh dữ liệu.

### `tests/`
`tests/powershell/` dùng Pester, tách theo từng Worker. Ưu tiên viết test cho các nhánh dễ sai nhất trước: tính dải IP cố định (7.2, công thức từng bị sửa ngược ở v1.1), tổng hợp Status cha (7.1), tính số ngày đã trôi qua có trừ SkippedDays (6.8-2), predicate hết hạn Cooldown +31 ngày (7.4). `tests/python/` dùng pytest cho từng collector — nên mock response SNMP/Meraki API, không gọi thiết bị thật trong CI.
