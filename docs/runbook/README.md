# Tài liệu quy trình vận hành (Runbook)

Đây là **deliverable bắt buộc theo hợp đồng** (thiết kế nhắc lại nhiều lần: 3.2, 10.5, 10.6, 10.7, 11.x), không phải tài liệu nội bộ tùy chọn. Cần hoàn thiện các file sau trước khi nghiệm thu:

- `operations-guide.md` — vận hành hằng ngày: đọc SharePoint view `ArpDeviceStatus` filter `CurrentStatus=Failed` (10.4), xử lý các thông báo Phụ lục F, quy trình xử lý case Failed (best effort, không SLA).
- `recovery-procedure.md` — thủ tục khôi phục sau restore VM/SharePoint: kiểm tra tính nhất quán 3 bên IPAM ⇔ SharePoint ⇔ DNS và resync (10.5), kèm script khôi phục custom field IPAM.
- `master-maintenance-checklist.md` — checklist chỉnh sửa trực tiếp SharePoint list bởi 3 thành viên team network/infrastructure (10.6): lưu ý lỗi network address/định dạng CIDR khi sửa `Segments`, thủ tục ngừng sử dụng segment/tháo thiết bị thu thập theo đúng 4 bước cố định thứ tự.
- `manual-deletion-checklist.md` — checklist xóa thủ công bởi IT qua IT Portal (10.7): 4 bước (xóa DNS, chuyển Cooldown, đặt Archived, cập nhật Status cha).
- `key-rotation.md` — quy trình xoay Meraki API key + gia hạn chứng chỉ Graph API (cảnh báo trước 60 ngày, 9.2).

Không viết nội dung các file trên bằng cách đoán — mỗi mục phải được xác nhận với đội vận hành thực tế (3 người vận hành theo NFR 3.2) trước khi chốt.
