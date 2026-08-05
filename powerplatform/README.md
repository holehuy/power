# Power Apps + Power Automate (Power Platform Solution)

Chỉ dùng **Standard connectors** (giới hạn license M365 E5, NFR 3.2) — kiểm tra lại mỗi khi thêm connector mới.

## Cấu trúc dự kiến sau khi `pac solution unpack`

```
powerplatform/
└── src/
    ├── CanvasApps/
    │   └── IPRegistrationApp/        # màn hình nhập đăng ký, xác nhận, lịch sử đăng ký (5.1)
    ├── Workflows/                    # Power Automate flow, tên file khớp Phụ lục F
    │   ├── flow-intake-request.json              # F#1 + ghi MissLog (7.1)
    │   ├── flow-completion-notification.json     # F#2
    │   ├── flow-failure-notification.json        # F#3
    │   ├── flow-deletion-stage-notification.json # F#4-#6, trigger theo IPRequestItems.NotificationStage
    │   └── flow-misslog-notification.json        # F#8
    └── Other/
```

## Vì sao không commit file `.msapp` gốc

`.msapp`/solution `.zip` là binary — không diff/review được trong PR. Quy trình chuẩn:

```bash
pac auth create --url https://<env>.crm.dynamics.com
pac solution export --name FixedIpAllocationSystem --path ./FixedIpAllocationSystem.zip --managed false
pac solution unpack --zipfile ./FixedIpAllocationSystem.zip --folder ./src
```

Sau khi sửa trong `./src`, pack lại và import vào môi trường:

```bash
pac solution pack --zipfile ./FixedIpAllocationSystem.zip --folder ./src
pac solution import --path ./FixedIpAllocationSystem.zip
```

## Quy tắc bắt buộc khi implement (đối chiếu thiết kế)

- **Flow độ song song = 1** cho mọi flow thông báo (`Concurrency Control` = 1 trong action Trigger) — quy ước chung 7.4, áp dụng cả F#2/#3 lẫn nhóm F#4–#6.
- Trigger theo thay đổi cột SharePoint **không phát hiện theo từng cột riêng lẻ** — mọi flow loại này phải tự thêm điều kiện lọc + kiểm tra cột "đã gửi" (`NotificationSentAt`/`CompletionNotifiedAt`/`FailureNotifiedAt`) trước khi gửi, để không phát hỏa trùng (7.4).
- Cascade dropdown Khu vực→Cơ sở→Segment: **không** tạo list `Sites` mới — dùng `Collect`/`Distinct` trên `Segments` tại `OnStart` (5.4), giới hạn dòng dữ liệu Power Apps nâng lên 2000.
- Combobox Segment: `Filter(Segments, SiteCode = ... && IsActive = true && RangeChangePending = false)` (5.4, v1.4) — loại trừ segment đang đổi range khỏi lựa chọn.
- Màn hình xác nhận: bắt buộc checkbox "Hostname đã đúng chưa?", **không hiển thị IP** trước khi gửi (IP do Worker cấp phát sau, 5.5).
