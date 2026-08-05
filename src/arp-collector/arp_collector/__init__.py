"""Worker thu thập ARP (thiết kế 7.3). Chạy mỗi giờ (bắt đầu phút 00).

Chỉ THU THẬP + ĐỐI CHIẾU + XUẤT JSON ở đây. Việc GHI vào IPAM được thực hiện bởi
script PowerShell riêng (`reflect-to-ipam/Invoke-ReflectArpResults.ps1`) chạy nối tiếp
trong cùng Task Scheduler job, vì IPAM chỉ thao tác được qua PowerShell module (7.3).
"""
