#Requires -Modules Pester
<#
    Test cho hàm dùng chung nguy hiểm nhất trong toàn hệ thống: Get-ElapsedDaysWithSkipCorrection
    (bản chuẩn 6.8-2). Mọi Worker tính hạn xóa đều gọi qua hàm này — sai ở đây là sai toàn hệ thống.
#>

BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\workers\common\IpamWorkerCommon.psm1" -Force
}

Describe 'Get-ElapsedDaysWithSkipCorrection' {

    It 'Trả về đúng số ngày khi không có SkippedDays' {
        $from = (Get-Date '2026-01-01T00:00:00Z')
        $asOf = (Get-Date '2026-01-31T00:00:00Z')
        Get-ElapsedDaysWithSkipCorrection -FromTimestampUtc $from -AsOfUtc $asOf -SkippedDays 0 | Should -Be 30
    }

    It 'Trừ đúng SkippedDays khỏi số ngày thô (6.8-2: hiệu chỉnh đóng băng)' {
        $from = (Get-Date '2026-01-01T00:00:00Z')
        $asOf = (Get-Date '2026-01-31T00:00:00Z')
        Get-ElapsedDaysWithSkipCorrection -FromTimestampUtc $from -AsOfUtc $asOf -SkippedDays 10 | Should -Be 20
    }

    It 'Không trả về số âm khi SkippedDays lớn hơn số ngày thô' {
        $from = (Get-Date '2026-01-01T00:00:00Z')
        $asOf = (Get-Date '2026-01-05T00:00:00Z')
        Get-ElapsedDaysWithSkipCorrection -FromTimestampUtc $from -AsOfUtc $asOf -SkippedDays 100 | Should -Be 0
    }

    It 'Tính theo ranh giới NGÀY sau khi quy đổi JST, không phải theo giờ tuyệt đối' {
        # 23:30 JST ngày 1/1 UTC+9 -> vẫn là ngày 1/1 JST; 00:30 JST ngày 2/1 UTC (tức 15:30 UTC ngày 1/1)
        # phải được tính là đã sang ngày 2/1 JST dù khoảng cách UTC chưa đủ 24h.
        $from = (Get-Date '2026-01-01T00:00:00Z')   # 09:00 JST ngày 1/1
        $asOf = (Get-Date '2026-01-01T15:30:00Z')    # 00:30 JST ngày 2/1 -> đã sang ngày mới theo JST
        Get-ElapsedDaysWithSkipCorrection -FromTimestampUtc $from -AsOfUtc $asOf -SkippedDays 0 | Should -Be 1
    }
}

Describe 'Get-ExternalThreshold' {

    BeforeAll {
        $script:tempConfig = New-TemporaryFile
        @{ validThreshold = 30; tooLowThreshold = 3 } | ConvertTo-Json | Set-Content $script:tempConfig
    }

    It 'Đọc đúng giá trị hợp lệ từ config' {
        Get-ExternalThreshold -ThresholdName 'validThreshold' -ConfigPath $script:tempConfig | Should -Be 30
    }

    It 'Từ chối giá trị nhỏ hơn guard tối thiểu 7 ngày (8.4)' {
        { Get-ExternalThreshold -ThresholdName 'tooLowThreshold' -ConfigPath $script:tempConfig } | Should -Throw
    }

    AfterAll {
        Remove-Item $script:tempConfig -ErrorAction SilentlyContinue
    }
}
