# Giải thích thuật ngữ & dịch vụ dùng trong luồng 7.3 (Worker thu thập ARP)

> Tài liệu bổ trợ — không phải bản thiết kế chính thức. Mục đích: giải thích các thuật ngữ, giao thức, dịch vụ xuất hiện trong `simple_design.md` mục 7.3 và code ở `src/workers/arp-worker/`, để đọc thiết kế không bị vướng vì thiếu ngữ cảnh kỹ thuật. Khi có sai khác, `simple_design.md` vẫn là source of trust.

---

## 1. Bối cảnh: tại sao cần "thu thập ARP"

Hệ thống này cấp IP cố định cho máy chủ/máy in/thiết bị mạng theo kiểu **thủ công** (2.1: không dùng MAC bind, không tạo DHCP reservation) — người dùng tự gõ IP vào máy. Vấn đề: khi ai đó tự gán một IP cố định vào máy **mà không đi qua hệ thống này**, không ai biết IP đó đang được dùng.

**ARP (Address Resolution Protocol)** là giao thức mạng dùng để ánh xạ giữa hai lớp:

| Lớp | Ví dụ |
|---|---|
| IP address (lớp 3) | `10.11.20.15` |
| MAC address (lớp 2, địa chỉ vật lý của card mạng) | `00:1A:2B:3C:4D:5E` |

Mọi router/switch/firewall trong mạng đều tự động duy trì một **bảng ARP** (ARP table) ghi lại "IP này hiện đang được trả lời bởi MAC này". Bảng này tồn tại sẵn để thiết bị mạng hoạt động — hệ thống không cần "hỏi" máy client, chỉ cần **đọc lại bảng ARP có sẵn trên switch/router/firewall**.

→ Đó chính là việc "Worker thu thập ARP" làm: **hỏi từng thiết bị mạng (router/switch/firewall) "bảng ARP của mày đang có gì", rồi so bảng đó với IPAM** để phát hiện IP nào đang được dùng ngoài luồng đăng ký chính thức (`Source=AutoDetected`) và xác nhận IP đã đăng ký (`Source=Requested`) có còn tồn tại (còn phản hồi) hay không.

---

## 2. Hai cách "hỏi" thiết bị mạng: SNMP và Meraki Dashboard API

7.3 dùng **2 cách khác nhau** tùy loại thiết bị, vì không phải thiết bị nào cũng hỗ trợ cùng một giao thức quản trị.

### 2.1 SNMP (Simple Network Management Protocol)

- Là giao thức chuẩn, rất cũ (từ thập niên 1990), gần như mọi thiết bị mạng doanh nghiệp (Cisco, FortiGate, Yamaha...) đều hỗ trợ.
- Cách hoạt động: server gửi truy vấn tới thiết bị bằng một "địa chỉ" gọi là **OID** (Object Identifier — giống như đường dẫn file, mỗi con số truy vấn một loại dữ liệu khác nhau trên thiết bị). Thiết bị trả lời bằng bảng dữ liệu.
- Trong 7.3, OID cần đọc là bảng ARP nội bộ của thiết bị:
  - `ipNetToPhysicalTable` (OID `1.3.6.1.2.1.4.35.1.4`) — chuẩn mới hơn.
  - `ipNetToMediaTable` (OID `1.3.6.1.2.1.4.22.1.2`) — chuẩn cũ, dùng làm **fallback** nếu thiết bị không hỗ trợ bảng mới.
- Thư viện Python dùng để nói chuyện SNMP: `pysnmp` (thấy trong [cisco_ios.py](../../src/workers/arp-worker/arp_collector/collectors/cisco_ios.py)).
- Tham số đã chốt (8.3): timeout 5 giây/thiết bị, retry 2 lần, độ song song = 1 (hỏi tuần tự từng máy, không hỏi đồng thời nhiều máy — để tránh làm quá tải CPU của thiết bị mạng cũ).
- Áp dụng cho: Cisco Catalyst (IOS), FortiGate, Yamaha RTX/NVR.

### 2.2 Meraki Dashboard API

- Meraki MX là dòng thiết bị **quản lý qua đám mây** (Cisco Meraki) — bản thân thiết bị không cho truy vấn SNMP trực tiếp theo cách các máy khác dùng ở đây; thay vào đó Cisco cung cấp sẵn một REST API đám mây gọi là **Meraki Dashboard API**.
- Endpoint dùng trong 7.3: `GET /networks/{networkId}/clients` — trả về danh sách client (máy) đang thấy trên network đó, kèm IP và MAC.
- Python gọi API này bằng SDK chính thức của Meraki (thư viện `meraki`), xác thực bằng API key (quyền Read-Only, 8.2).
- Khác biệt quan trọng với SNMP: Meraki cần 2 ID khác nhau —
  - `MerakiOrgId`: ID tổ chức, chỉ dùng để **ghi sổ/vận hành**, không dùng trong lúc thu thập.
  - `MerakiNetworkId`: ID mạng cụ thể, **đây mới là ID thật sự dùng để gọi API** (`/networks/{MerakiNetworkId}/clients`).

### 2.3 Vì sao phải phân biệt theo `DeviceType`

Mỗi thiết bị trong danh sách `ArpDeviceStatus` có một cột `DeviceType` (`CiscoIOS` / `FortiGate` / `YamahaRTX` / `MerakiMX`) — đây là "công tắc" quyết định code sẽ dùng SNMP hay Meraki API để hỏi thiết bị đó (xem [main.py:21-26](../../src/workers/arp-worker/arp_collector/main.py#L21-L26), biến `DEVICE_TYPE_DISPATCH`). Nếu cột này để trống hoặc gõ sai giá trị, Worker sẽ **bỏ qua thiết bị đó và tính là một lần thất bại** (không âm thầm bỏ qua — nguyên tắc "cấm silent error", 8.4).

---

## 3. Windows IPAM — kho dữ liệu IP trung tâm

**IPAM (IP Address Management)** là một **tính năng có sẵn của Windows Server** (không phải phần mềm tự viết), dùng để quản lý tập trung: IP nào đang cấp, cho ai, DHCP scope nào, DNS nào liên quan...

Thiết kế xác định (2.1): **Windows IPAM là "Source of Truth" (nguồn sự thật) của toàn bộ địa chỉ IP** trong hệ thống — không phải SharePoint, không phải DHCP. Nghĩa là: muốn biết một IP có đang được dùng hay không, tra trong IPAM là câu trả lời đúng nhất.

### Vì sao PowerShell là bên duy nhất được ghi vào IPAM

Windows IPAM **chỉ expose quyền quản trị qua module PowerShell tên là `IpamServer`** — không có REST API, không có SDK cho ngôn ngữ khác (Python, v.v.) để thao tác trực tiếp lên IPAM. Đây là lý do kỹ thuật xác định ở v1.1 (`simple_design.md` dòng 1165):

> "IPAMはPowerShellモジュール経由でのみ操作可能なため" — "vì IPAM chỉ thao tác được thông qua PowerShell module"

Vài cmdlet PowerShell tiêu biểu (8.3):

| Cmdlet | Việc làm |
|---|---|
| `Get-IpamAddress` | Tra cứu 1 địa chỉ IP đã có trong IPAM chưa, đang ở trạng thái/Source nào |
| `Add-IpamAddress` | Đăng ký 1 IP mới vào IPAM |
| `Set-IpamAddress` | Cập nhật thông tin của IP đã có (VD: cập nhật `LastSeenAt`) |
| `Remove-IpamAddress` | Xóa IP khỏi IPAM (trả về pool trống) |
| `Find-IpamFreeAddress` | Tìm IP còn trống để cấp phát (dùng ở Worker payout, không thuộc 7.3) |

Vì vậy trong 7.3: **Python chỉ được phép đọc thiết bị mạng và xuất kết quả ra file JSON** — còn "ghi vào IPAM thật" bắt buộc phải qua PowerShell (xem lại giải thích ở câu hỏi trước của bạn: cơ chế bàn giao qua file).

### Custom field trên IPAM (6.1)

IPAM chuẩn của Windows không có sẵn các cột hệ thống này cần — nên thiết kế định nghĩa thêm 4 **custom field** (giống như thêm cột tùy biến vào 1 bảng có sẵn):

| Custom field | Ý nghĩa |
|---|---|
| `Source` | IP này đến từ đâu: `Requested` (người dùng đăng ký qua Power Apps), `AutoDetected` (ARP phát hiện ra, không qua đăng ký), hoặc có thêm giá trị `Cooldown` (đang trong giai đoạn giữ 30 ngày sau khi bị xóa, xem mục 5 bên dưới) |
| `RequestId` | Liên kết ngược về bản ghi đăng ký gốc trong SharePoint (`IPRequestItems`), dạng `REQ-yyyymmdd-{ID cha}-{ID chi tiết}` |
| `LastSeenAt` | Lần cuối ARP nhìn thấy IP này còn phản hồi — đây là "đồng hồ" để tính hạn xóa tự động (7.4) |
| `CooldownStartedAt` | Thời điểm bắt đầu tính 30 ngày giữ (Cooldown) sau khi bị xóa |

---

## 4. SharePoint list — nơi lưu dữ liệu "master" (không phải IPAM)

Có 2 SharePoint list mà Worker 7.3 đọc/ghi trực tiếp — về bản chất đây là **bảng dữ liệu** (giống Excel có cấu trúc, hoặc 1 table trong database), không phải "trang web":

- **`ArpDeviceStatus`** — danh sách thiết bị cần quét ARP (mục 6.9). Vừa là **master thiết bị** (đội network tự thêm/sửa/xóa thiết bị ở đây), vừa là **nơi Worker ghi lại trạng thái** sau mỗi lần quét (`LastSuccessAt`, `ConsecutiveFailureCount`, `CurrentStatus`...).
- **`Segments`** (mục 6.3) — danh sách toàn bộ segment mạng (CIDR, có DHCP scope hay không, dải IP cố định...). Worker 7.3 chỉ **đọc** list này (lấy snapshot đầu chu kỳ) để biết IP nào thuộc "dải cố định" cần theo dõi, IP nào thuộc "dynamic pool" (vùng DHCP tự động cấp — bỏ qua, không lập sổ).

Cả Python lẫn PowerShell đều đọc/ghi 2 list này thông qua **Microsoft Graph API** — API chuẩn của Microsoft để thao tác dữ liệu Microsoft 365 (SharePoint, Outlook, Teams...) bằng HTTP. Xác thực dùng **Entra ID app registration + chứng chỉ** (8.2), không dùng tài khoản người dùng thật.

---

## 5. Các trạng thái vòng đời của một IP (thuật ngữ hay gặp nhất)

Đây là phần dễ rối nhất khi đọc 7.3/7.4, vì các từ `Source`, `Cooldown`, `AutoDetected`, `RangeChangePending` lặp lại liên tục. Tóm tắt vòng đời:

```
Chưa ai biết IP này tồn tại
        │  (ARP phát hiện, không có RequestId)
        ▼
   Source = AutoDetected  ──── không phản hồi 1 tháng ───┐
        ▲                                                 ▼
        │ (ARP thấy lại IP này còn sống)           Source += Cooldown
        │                                          (giữ 30 ngày, không xóa hẳn)
        └───────────── khôi phục (7.3 nhánh a) ──────────┘
                                                            │ hết 30 ngày + 1 ngày xác nhận
                                                            ▼
                                                    xóa vật lý khỏi IPAM
                                                    (IP quay lại pool trống)

   Source = Requested  (người dùng đăng ký qua Power Apps)
        │  không phản hồi 3/6/12 tháng
        ▼
   nhắc nhở → nhắc nhở → xóa archive (7.4, không nằm trong 7.3)
```

Vài thuật ngữ đứng riêng:

- **`IsActive` (trên Segments)**: cờ "segment này còn dùng không". Nếu `false`, Worker 7.3 sẽ **không đăng ký AutoDetected mới** trong segment đó nữa, nhưng vẫn **tiếp tục cập nhật `LastSeenAt`** cho IP đã có sẵn (thiết kế cố ý bất đối xứng — đăng ký mới thì chặn, nhưng đã có rồi thì vẫn theo dõi, để không xóa nhầm máy còn đang chạy).
- **`RangeChangePending` (trên Segments)**: cờ báo "dải IP của segment này đang trong quá trình thay đổi ở phía DHCP, dữ liệu IPAM/Segments có thể chưa kịp cập nhật". Khi cờ này bật, Worker 7.3 **tạm giữ (không đăng ký AutoDetected mới)** để tránh đăng ký nhầm IP vào lúc dữ liệu chưa nhất quán.
- **Dynamic pool** vs **dải IP cố định (static range)**: dynamic pool là vùng IP mà DHCP tự cấp phát ngẫu nhiên cho máy client (laptop, điện thoại...) — hệ thống này **không quan tâm** vùng đó. Dải cố định là phần còn lại của segment, nơi máy chủ/máy in/thiết bị được gán IP thủ công — đây mới là vùng ARP cần theo dõi.

---

## 6. Cơ chế "chống dẫm chân nhau" — Mutex / Lock file

Vì có nhiều Worker (payout, đồng bộ segment, thu thập ARP, tự động xóa) cùng có thể động vào 1 địa chỉ IP trong IPAM tại các thời điểm gần nhau, thiết kế (8.4) yêu cầu:

- **Lock file chống chạy đa instance**: đảm bảo cùng 1 Worker không tự chạy chồng lên chính nó nếu lần chạy trước chưa xong (VD: ARP quét lâu hơn 1 giờ).
- **Mutex theo từng IP** (named mutex khóa theo địa chỉ IP cụ thể): đảm bảo Worker tự động xóa và PowerShell Reflector của ARP không cùng sửa **đúng 1 IP** tại cùng một khoảnh khắc — mỗi IP có "khóa" riêng, chỉ khóa trong lúc đang ghi, không khóa toàn bộ IPAM (tránh việc 1 Worker chạy lâu làm đứng toàn bộ hệ thống).

---

## 7. Đích thông báo — `nkis-network` và SMTP relay

`nkis-network@nkc.co.jp` là **hộp thư của đội Network/Infrastructure nội bộ** — nơi nhận mọi cảnh báo vận hành do Worker tự động gửi (thiết bị mất kết nối 72 giờ, nghi ngờ xung đột IP, khôi phục IP từ Cooldown...). Worker không tự gửi email qua Internet — mà gửi qua một **SMTP relay nội bộ** (máy chủ mail trung gian trong mạng công ty), vì server Worker (Azure VM) không có quyền gửi mail ra ngoài trực tiếp; IP của Worker phải được admin thêm vào danh sách cho phép relay trước.

---

## 8. Tổng hợp: đường đi 1 "gói tin ARP" qua toàn bộ 7.3

1. Task Scheduler đánh thức job lúc phút :00 mỗi giờ.
2. Python đọc `ArpDeviceStatus` → biết cần hỏi thiết bị nào, bằng cách nào (`DeviceType`).
3. Với từng thiết bị: SNMP hoặc Meraki API trả về bảng `IP ↔ MAC ↔ thời điểm`.
4. Python ghi lại "thiết bị này vừa quét OK hay lỗi" vào `ArpDeviceStatus` (đếm lỗi liên tiếp, 72 lần → `Failed`).
5. Python xuất toàn bộ kết quả thô ra 1 file JSON — **không đụng vào IPAM**.
6. PowerShell (chạy nối tiếp, cùng Task Scheduler job) đọc file JSON đó + snapshot `Segments`.
7. Với từng IP: bỏ qua nếu thuộc dynamic pool; nếu thuộc dải cố định thì tra `Get-IpamAddress` rồi ghi vào IPAM theo 1 trong 3 nhánh (đã vẽ ở Fig. 2 của artifact trước) bằng `Add-IpamAddress`/`Set-IpamAddress`, có khóa mutex theo IP.
8. Nếu phát hiện bất thường (thiết bị Failed, MAC lạ trên IP đã đăng ký, IP khôi phục từ Cooldown...) → gửi mail tới `nkis-network` qua SMTP relay.
9. Ghi log kết quả vào Windows Event Log `IPAM-Worker`.

---

*Nguồn: `simple_design.md` mục 7.3 (dòng 1151–1191), mục 6.3/6.9/8.2/8.3/8.4; bản dịch `docs/design/Fixed IP Address Auto Allocation System Design v1.4.md` dòng 620–660; code tham chiếu tại `src/workers/arp-worker/`.*
