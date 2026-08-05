#Requires -Modules Pester
<#
    Worker rủi ro cao nhất trong hệ thống (7.4). Các test này định hình HÀNH VI KỲ VỌNG trước khi
    implement phần thân (TDD) — hiện Describe bên dưới đang -Skip vì logic thật còn nằm trong
    Invoke-AutoDeletionWorker.ps1 dưới dạng vòng lặp trực tiếp, chưa tách hàm để test được.

    Việc ĐẦU TIÊN cần làm khi hiện thực worker này: tách các bước (2)-(6) trong file .ps1 thành
    hàm riêng có input/output rõ ràng (nhận snapshot làm tham số, trả về danh sách hành động dự kiến)
    để có thể unit test mà không cần IPAM/SharePoint thật.
#>

Describe 'Predicate hết hạn Cooldown (7.4: +31 ngày, không phải +30)' -Skip {

    It 'KHÔNG xóa vật lý ở đúng ngày thứ 30' {
    }

    It 'Xóa vật lý ở ngày thứ 31 (30 giữ + 1 xác nhận, Phụ lục A/B)' {
    }

    It 'KHÔNG xóa nếu LastSeenAt > CooldownStartedAt (đang trong quá trình khôi phục, điều kiện (3))' {
    }

    It 'KHÔNG xóa nếu Source không còn chứa Cooldown (đã khôi phục xong, điều kiện (2))' {
    }
}

Describe 'Segment loại trừ khỏi tự động xóa (7.4: tính lại runtime, KHÔNG phụ thuộc IsActive)' -Skip {

    It 'Loại trừ segment do thiết bị phụ trách đang CurrentStatus=Failed' {
    }

    It 'Loại trừ segment không nằm trong TargetSegments của bất kỳ ArpDeviceStatus nào (chưa cover)' {
    }

    It 'Segment loại trừ vẫn được cộng SkippedDays kể cả khi IsActive=false' {
    }
}

Describe 'Bộ đệm khi gỡ skip (7.4)' -Skip {

    It 'Tối đa 1 bậc chuyển NotificationStage trong 1 lần chạy sau khi gỡ skip' {
    }

    It 'KHÔNG xóa archive 12 tháng ở lần chạy đầu tiên ngay sau khi gỡ skip' {
    }
}

Describe 'Snapshot đầu ca quét (7.4: không dao động giữa chừng)' -Skip {

    It 'Thay đổi CurrentStatus của thiết bị giữa lúc quét KHÔNG ảnh hưởng phán định của ca quét hiện tại' {
    }
}
