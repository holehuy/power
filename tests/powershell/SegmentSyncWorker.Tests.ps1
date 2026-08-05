#Requires -Modules Pester
<#
    Get-FixedIpRange là công thức đã bị SỬA NGƯỢC ở v1.1 (7.2) — viết test này TRƯỚC khi implement
    (TDD), không phải sau. Hiện tại hàm còn là stub (`throw 'TODO'`) nên các It bên dưới đang Skip.
    Bỏ -Skip ngay khi Get-FixedIpRange trong Invoke-SegmentSyncWorker.ps1 có thân hàm thật.
#>

Describe 'Get-FixedIpRange (7.2)' -Skip {

    It 'Dải IP cố định = host range CIDR − (scope range − exclusion range) − reserved IP' {
        # Segment /24: 254 host khả dụng (trừ network/broadcast).
        # Scope range = toàn bộ /24, exclusion range = .200-.254 (55 địa chỉ) => dynamic pool = .1-.199 (199 địa chỉ, dùng làm DHCP động).
        # => dải IP cố định kỳ vọng = .200-.254 (trừ .254 nếu là broadcast/gateway theo cấu hình test).
        # TODO: gọi Get-FixedIpRange -Cidr '10.0.0.0/24' -ScopeRange ... -ExclusionRanges ... rồi so khớp danh sách địa chỉ kỳ vọng.
    }

    It 'Không được tính nhầm dynamic pool là dải IP cố định (lỗi đã xảy ra ở v1.0, sửa ở v1.1)' {
        # Test hồi quy: đảm bảo không lặp lại lỗi "công thức chỉ ra chính dynamic pool" đã ghi trong lịch sử sửa đổi v1.1.
    }

    It 'Segment DhcpScopeExists=false: dải IP cố định = toàn bộ CIDR trừ reserved IP (3.1/7.2)' {
    }
}

Describe 'Update-RangeChangePendingFlags — điều kiện gỡ khi MỞ RỘNG phạm vi (7.2)' -Skip {

    It 'Chỉ gỡ RangeChangePending khi LastSuccessAt của MỌI thiết bị phụ trách mới hơn LastSyncedAt của segment' {
    }

    It 'KHÔNG gỡ khi thiết bị phụ trách đang Failed (thiên về an toàn, nhất quán với skip xóa do Failed)' {
    }
}
