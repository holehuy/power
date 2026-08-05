# Danh sách câu hỏi / giá trị còn treo

Nguồn: tài liệu thiết kế v1.4, mục 1.3/1.4 lịch sử sửa đổi + Phụ lục C + Phụ lục G (RACI).
Cập nhật file này liên tục trong suốt dự án — đừng để nó trở thành ảnh chụp một lần rồi lỗi thời.

## A. Giá trị thực tế còn hoãn từ v1.3 (8 mục)

- [ ] FQDN server DNS ghi thực tế
- [ ] Giá trị thực SMTP relay (địa chỉ gửi + FQDN relay)
- [ ] Thời điểm hoàn tất khảo sát trước, ngoài C.1/C.6
- [ ] Thời điểm cung cấp nội dung mẫu thông báo (chương 13 — không có trong bản thiết kế hiện có, cần xin bản đầy đủ)
- [ ] Severity mục tiêu của PSScriptAnalyzer ("重大")
- [ ] Ngưỡng đạt của đo thực tế 1 cycle thu thập ARP
- [ ] Thời điểm phê duyệt bảng quan điểm test tích hợp
- [ ] Mẫu văn bản email alert phát từ Worker

## B. Phụ lục C — Checklist khảo sát trước (chặn đường build)

- [ ] **C.1** Đối chiếu inconsistency scope DHCP theo cặp — đã phát hiện sẵn 1 lỗi (Bonken factory 172.31.140.0, EndRange lệch nkdc4=.219 / nkdc5=.229), cần khách hàng xác nhận giá trị đúng
- [ ] **C.2** Giới hạn rate-limit Meraki Dashboard API — số org/network/MX thực tế
- [ ] **C.3** Kết nối Azure VM → 2 DHCP server nước ngoài — kết quả đo thực tế + yêu cầu mở FW
- [ ] **C.4** Giới hạn request Power Automate trong quota Power Platform của license E5
- [ ] **C.5** Thời gian lưu version history SharePoint có đáp ứng yêu cầu audit nội bộ/pháp lý không
- [ ] **C.6** Khả năng SNMP reachability + cấu hình phía thiết bị (ACL/community/SNMPv3) cho toàn bộ thiết bị thu thập ARP — kèm danh sách DeviceType + MerakiOrgId/MerakiNetworkId (dùng làm dữ liệu nhập ban đầu ArpDeviceStatus)

## C. RACI (Phụ lục G) — việc khách hàng phải hoàn thành trước khi vendor build được

- [ ] Subscription / VNet / subnet / NSG / quy tắc đặt tên Azure
- [ ] Site SharePoint / scope DHCP / subzone DNS dùng cho môi trường kiểm thử
- [ ] Cấp tài khoản thời hạn cho nhân sự vendor + kết nối VPN sẵn có
- [ ] Tạo GPO quản lý IPAM (vendor cung cấp tài liệu định nghĩa/hướng dẫn/kiểm thử)
- [ ] Admin consent cho đăng ký ứng dụng Entra ID
- [ ] Danh sách dữ liệu ban đầu ArpDeviceStatus (khách hàng tạo danh sách, vendor nhập bằng CSV tool)
- [ ] Dữ liệu ban đầu master Segments (~1000 record)
- [ ] Đăng ký IP Worker server làm nguồn được phép relay trên SMTP nội bộ
- [ ] Cấu hình SNMP ACL/community trên thiết bị NW mục tiêu
- [ ] Sửa inconsistency scope DHCP theo cặp (xem C.1)
- [ ] Xác nhận khả thi gMSA (chuẩn bị KDS root key)
- [ ] Xác định mailbox gửi của Power Automate
- [ ] Quyết định lộ trình rollout theo cơ sở + thời điểm chuyển ngưỡng xóa ban đầu (90 ngày) sang định thường (30 ngày) — xem 10.2/A-3
- [ ] Resource group đích để deploy hạ tầng (`infra/bicep/` — VM IPAM+Worker, Recovery Services vault, heartbeat alert): dùng chung 1 resource group hiện có của khách hàng, hay tạo mới riêng cho hệ thống này? Nếu dùng chung, đề nghị khách hàng chỉ định rõ tên/ID resource group đó trước khi deploy (README.md § Infrastructure Deployment)
- [ ] Join domain AD nội bộ cho Azure VM (§8.1 thiết kế chỉ ghi "theo kinh nghiệm vận hành hiện có", không chỉ rõ chủ thể): xác nhận với khách hàng — vendor thực hiện thao tác join (thuộc phạm vi "cấu hình OS" trong RACI), nhưng khách hàng cần cấp trước tài khoản có quyền join domain (nằm trong mục "cấp tài khoản thời hạn cho nhân sự vendor" ở trên) và xác nhận OU/naming policy cho computer object nếu có quy định riêng

## D. Khoảng trống trong bản thiết kế đang có

- Chương 11 (đầy đủ, gồm 11.1 tổng hợp công số, 11.2, 11.3 điều kiện đặt hàng) và chương 13 (mẫu nội dung thông báo) được tham chiếu nhiều lần trong nội dung nhưng không có trong bản Việt hóa hiện tại (`docs/design/`). Cần xin bản gốc đầy đủ trước khi ước lượng effort hoặc soạn mẫu email thật.
