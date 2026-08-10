#Requires -Modules Pester
<#
    Test cho Common.psm1: hàm dùng chung nguy hiểm nhất trong toàn hệ thống
    (Get-ElapsedDaysWithSkipCorrection, bản chuẩn 6.8-2 — mọi Worker tính hạn xóa đều gọi qua hàm
    này, sai ở đây là sai toàn hệ thống), Get-ExternalThreshold, và Write-WorkerLog/LogLevel.
#>

BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\common\Common.psm1" -Force
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

Describe 'Write-WorkerLog — LogLevel' {
    # Stub trước cho Write-EventLog (chỉ tồn tại trên Windows) — cùng quy ước với
    # ReflectArpResults.Tests.ps1: định nghĩa trước để Pester Mock có function cụ thể để ghi đè,
    # không phụ thuộc môi trường chạy test (Docker dev-toolchain Linux/Mac không có cmdlet này).
    function Write-EventLog { param($LogName, $Source, $EventId, $EntryType, $Message) }

    BeforeEach {
        Mock Write-EventLog -ModuleName Common {}
        $script:tempLogDir = Join-Path ([System.IO.Path]::GetTempPath()) "worklog-test-$(New-Guid)"
    }

    AfterEach {
        Set-WorkerLogLevel -Level Information  # reset — CurrentLogLevel là script-scope, rò sang Describe khác nếu không reset
        Remove-Item $script:tempLogDir -Recurse -ErrorAction SilentlyContinue
    }

    It 'Ghi Information vào file log khi LogLevel mặc định (Information)' {
        Write-WorkerLog -Message 'msg-info' -Level Information -LogDirectory $script:tempLogDir
        $logFile = Join-Path $script:tempLogDir "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
        Get-Content $logFile -Raw | Should -Match 'msg-info'
    }

    It 'Debug bị lọc khỏi file log khi LogLevel mặc định (Information)' {
        Write-WorkerLog -Message 'msg-debug' -Level Debug -LogDirectory $script:tempLogDir
        $logFile = Join-Path $script:tempLogDir "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
        Test-Path $logFile | Should -Be $false
    }

    It 'Set-WorkerLogLevel Warning loc bo Information, van ghi Warning' {
        Set-WorkerLogLevel -Level Warning
        Write-WorkerLog -Message 'msg-info-filtered' -Level Information -LogDirectory $script:tempLogDir
        Write-WorkerLog -Message 'msg-warning-kept' -Level Warning -LogDirectory $script:tempLogDir
        $logFile = Join-Path $script:tempLogDir "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
        $content = Get-Content $logFile -Raw
        $content | Should -Not -Match 'msg-info-filtered'
        $content | Should -Match 'msg-warning-kept'
    }

    It 'Error luon duoc ghi ke ca khi LogLevel cau hinh = Error (nguong cao nhat)' {
        Set-WorkerLogLevel -Level Error
        Write-WorkerLog -Message 'msg-error-kept' -Level Error -LogDirectory $script:tempLogDir
        Write-WorkerLog -Message 'msg-warning-filtered' -Level Warning -LogDirectory $script:tempLogDir
        $logFile = Join-Path $script:tempLogDir "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
        $content = Get-Content $logFile -Raw
        $content | Should -Match 'msg-error-kept'
        $content | Should -Not -Match 'msg-warning-filtered'
    }

    It 'Debug khong ghi vao Event Log ke ca khi LogLevel=Debug (chi ghi file log)' {
        Set-WorkerLogLevel -Level Debug
        Write-WorkerLog -Message 'msg-debug-eventlog' -Level Debug -LogDirectory $script:tempLogDir
        Should -Invoke Write-EventLog -ModuleName Common -Times 0
    }

    It 'Information co ghi vao Event Log' {
        Set-WorkerLogLevel -Level Debug
        Write-WorkerLog -Message 'msg-info-eventlog' -Level Information -LogDirectory $script:tempLogDir
        Should -Invoke Write-EventLog -ModuleName Common -Times 1
    }
}

Describe 'Expand-MessageTemplate' {

    It 'Thay dung 1 token' {
        Expand-MessageTemplate -Text 'Xin chao {{Name}}' -Parameters @{ Name = 'Huy' } | Should -Be 'Xin chao Huy'
    }

    It 'Thay dung nhieu token khac nhau' {
        $result = Expand-MessageTemplate -Text '{{A}} va {{B}}' -Parameters @{ A = '1'; B = '2' }
        $result | Should -Be '1 va 2'
    }

    It 'Thay dung token lap lai nhieu lan' {
        $result = Expand-MessageTemplate -Text '{{Ip}} - {{Ip}}' -Parameters @{ Ip = '10.0.0.1' }
        $result | Should -Be '10.0.0.1 - 10.0.0.1'
    }

    It 'Khong co token nao -> tra nguyen van' {
        Expand-MessageTemplate -Text 'Khong co token' -Parameters @{} | Should -Be 'Khong co token'
    }

    It 'Throw khi thieu param bat buoc cho 1 token (cam silent error, 8.4)' {
        { Expand-MessageTemplate -Text 'Xin chao {{Name}}' -Parameters @{} } | Should -Throw
    }
}

Describe 'Get-LogMessageTemplate' {

    BeforeAll {
        $script:tempCatalog = New-TemporaryFile
        @{
            'INFO-TEST-0001' = 'Bat dau {{Name}}.'
            'ERR-TEST-0001'  = 'Loi {{ItemId}}: {{Detail}}'
        } | ConvertTo-Json | Set-Content $script:tempCatalog
    }

    AfterAll {
        Remove-Item $script:tempCatalog -ErrorAction SilentlyContinue
    }

    It 'Tra dung message template theo Code' {
        Get-LogMessageTemplate -Code 'INFO-TEST-0001' -CatalogPath $script:tempCatalog | Should -Be 'Bat dau {{Name}}.'
    }

    It 'Throw khi Code khong ton tai trong catalog' {
        { Get-LogMessageTemplate -Code 'ERR-TEST-9999' -CatalogPath $script:tempCatalog } | Should -Throw
    }
}

Describe 'Write-InfoLog / Write-WarningLog / Write-ErrorLog / Write-DebugLog' {
    function Write-EventLog { param($LogName, $Source, $EventId, $EntryType, $Message) }

    BeforeAll {
        # Dùng Worker-ID THẬT (ALLOC, SYNC — đã đăng ký trong $script:WorkerIdEventIdBase của
        # Common.psm1) thay vì 1 Worker-ID giả, vì giờ EventId tính từ bảng đó — Worker-ID chưa
        # đăng ký sẽ throw (xem test riêng bên dưới).
        $script:tempCatalog2 = New-TemporaryFile
        @{
            'INFO-ALLOC-0001' = 'Bat dau {{Name}}.'
            'WARN-ALLOC-0002' = 'Canh bao {{Name}}.'
            'ERR-ALLOC-0001'  = 'Loi {{ItemId}}: {{Detail}}'
            'INFO-SYNC-0001'  = 'Bat dau dong bo.'
        } | ConvertTo-Json | Set-Content $script:tempCatalog2
    }

    AfterAll {
        Remove-Item $script:tempCatalog2 -ErrorAction SilentlyContinue
    }

    BeforeEach {
        Mock Write-EventLog -ModuleName Common {}
        Set-WorkerLogLevel -Level Debug
        $script:tempLogDir2 = Join-Path ([System.IO.Path]::GetTempPath()) "codedlog-test-$(New-Guid)"
    }

    AfterEach {
        Set-WorkerLogLevel -Level Information
        Set-CurrentWorkerId -WorkerId 'ALLOC'  # reset — CurrentWorkerId là script-scope, rò sang test khác nếu không reset
        Remove-Item $script:tempLogDir2 -Recurse -ErrorAction SilentlyContinue
    }

    It 'Write-InfoLog qua -Code ghi dung Level=Information, EventId tu suy = WorkerIdEventIdBase[ALLOC] = 2000, message co prefix [Code]' {
        Write-InfoLog -Code 'INFO-ALLOC-0001' -Parameters @{ Name = 'X' } `
            -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        $logFile = Join-Path $script:tempLogDir2 "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
        $content = Get-Content $logFile -Raw
        $content | Should -Match '\[Information\]'
        $content | Should -Match '\[INFO-ALLOC-0001\] Bat dau X\.'
        Should -Invoke Write-EventLog -ModuleName Common -Times 1 -ParameterFilter { $EventId -eq 2000 }
    }

    It 'Truyen tay -EventId thi dung dung gia tri do, khong tu suy nua (vd giu dung EventId thiet ke goc cua ARP)' {
        Write-InfoLog -Code 'INFO-ALLOC-0001' -EventId 1001 `
            -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        Should -Invoke Write-EventLog -ModuleName Common -Times 1 -ParameterFilter { $EventId -eq 1001 }
    }

    It 'IncludeCodePrefix:$false thi KHONG con prefix [Code], chi con message thuan' {
        Write-InfoLog -Code 'INFO-ALLOC-0001' -Parameters @{ Name = 'X' } -IncludeCodePrefix:$false `
            -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        $logFile = Join-Path $script:tempLogDir2 "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
        $content = Get-Content $logFile -Raw
        $content | Should -Not -Match '\[INFO-ALLOC-0001\]'
        $content | Should -Match 'Bat dau X\.'
    }

    It '3 Level khac nhau cung 1 Worker (ALLOC) CUNG 1 EventId mac dinh (2000) — don gian hoa theo yeu cau, khong phan theo Level' {
        Write-InfoLog -Code 'INFO-ALLOC-0001' -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        Write-WarningLog -Code 'WARN-ALLOC-0002' -Parameters @{ Name = 'Y' } -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        Write-ErrorLog -Code 'ERR-ALLOC-0001' -Parameters @{ ItemId = 'x'; Detail = 'y' } -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        Should -Invoke Write-EventLog -ModuleName Common -Times 3 -ParameterFilter { $EventId -eq 2000 }
    }

    It 'Write-WarningLog ghi dung Level=Warning' {
        Write-WarningLog -Code 'WARN-ALLOC-0002' -Parameters @{ Name = 'Y' } `
            -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        $logFile = Join-Path $script:tempLogDir2 "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
        Get-Content $logFile -Raw | Should -Match '\[Warning\]'
    }

    It 'Write-ErrorLog ghi dung Level=Error' {
        Write-ErrorLog -Code 'ERR-ALLOC-0001' -Parameters @{ ItemId = 'IT-1'; Detail = 'timeout' } `
            -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        $logFile = Join-Path $script:tempLogDir2 "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
        Get-Content $logFile -Raw | Should -Match '\[Error\].*Loi IT-1: timeout'
    }

    It 'Write-DebugLog ghi dung Level=Debug qua -Message, KHONG goi Write-EventLog (Debug chi ghi file log)' {
        Set-CurrentWorkerId -WorkerId 'ALLOC'
        Write-DebugLog -Message 'Chi tiet debug' -LogDirectory $script:tempLogDir2
        $logFile = Join-Path $script:tempLogDir2 "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
        $content = Get-Content $logFile -Raw
        $content | Should -Match '\[Debug\] Chi tiet debug'
        Should -Invoke Write-EventLog -ModuleName Common -Times 0
    }

    It 'EventId KHONG trung giua 2 Worker khac nhau (ALLOC=2000, SYNC=3000)' {
        Write-InfoLog -Code 'INFO-ALLOC-0001' -Parameters @{ Name = 'X' } `
            -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        Write-InfoLog -Code 'INFO-SYNC-0001' `
            -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        Should -Invoke Write-EventLog -ModuleName Common -Times 1 -ParameterFilter { $EventId -eq 2000 }
        Should -Invoke Write-EventLog -ModuleName Common -Times 1 -ParameterFilter { $EventId -eq 3000 }
    }

    It 'Throw khi goi Write-InfoLog voi Code prefix ERR- (prefix khong khop ham goi)' {
        { Write-InfoLog -Code 'ERR-ALLOC-0001' -Parameters @{ ItemId = 'IT-1'; Detail = 'x' } `
            -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2 } | Should -Throw
    }

    It 'Throw khi Code sai dinh dang (thieu XXXX 4 so)' {
        { Write-InfoLog -Code 'INFO-ALLOC-1' -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2 } | Should -Throw
    }

    It 'Throw khi Worker-ID chua duoc dang ky trong $script:WorkerIdEventIdBase' {
        Set-Content -Path (Join-Path ([System.IO.Path]::GetDirectoryName($script:tempCatalog2)) 'unregistered.json') `
            -Value (@{ 'INFO-ZZZZ-0001' = 'Test.' } | ConvertTo-Json)
        $unregisteredCatalog = Join-Path ([System.IO.Path]::GetDirectoryName($script:tempCatalog2)) 'unregistered.json'
        { Write-InfoLog -Code 'INFO-ZZZZ-0001' -LogDirectory $script:tempLogDir2 -CatalogPath $unregisteredCatalog } | Should -Throw
        Remove-Item $unregisteredCatalog -ErrorAction SilentlyContinue
    }

    It 'Throw khi thieu param bat buoc cua template' {
        { Write-ErrorLog -Code 'ERR-ALLOC-0001' -Parameters @{ ItemId = 'IT-1' } `
            -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2 } | Should -Throw
    }

    It 'Throw khi khong truyen ca -Code lan -Message' {
        { Write-InfoLog -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2 } | Should -Throw
    }

    It '-Message (khong Code) ghi dung noi dung, khong co prefix [Code]' {
        Write-InfoLog -Message 'Ban tin tu do' -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        $logFile = Join-Path $script:tempLogDir2 "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
        $content = Get-Content $logFile -Raw
        $content | Should -Match 'Ban tin tu do'
        $content | Should -Not -Match '\[INFO-'
    }

    It '-Message tu suy EventId theo Get-CurrentWorkerId da dang ky truoc (Set-CurrentWorkerId)' {
        Set-CurrentWorkerId -WorkerId 'SYNC'
        Write-InfoLog -Message 'Ban tin cua SYNC' -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        Should -Invoke Write-EventLog -ModuleName Common -Times 1 -ParameterFilter { $EventId -eq 3000 }
    }

    It '-Message khong co Set-CurrentWorkerId truoc va khong -EventId thi throw' {
        # $script:CurrentWorkerId là biến module-scope BÊN TRONG Common.psm1 — set trực tiếp từ
        # file test (dù cũng dùng "$script:") KHÔNG chạm được vào nó, phải qua InModuleScope.
        InModuleScope Common { $script:CurrentWorkerId = $null }
        { Write-InfoLog -Message 'x' -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2 } | Should -Throw
        Set-CurrentWorkerId -WorkerId 'ALLOC'
    }

    It 'Uu tien -Code hon -Message khi ca 2 cung duoc truyen' {
        Write-InfoLog -Code 'INFO-ALLOC-0001' -Message 'Bi bo qua' -Parameters @{ Name = 'X' } `
            -LogDirectory $script:tempLogDir2 -CatalogPath $script:tempCatalog2
        $logFile = Join-Path $script:tempLogDir2 "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
        $content = Get-Content $logFile -Raw
        $content | Should -Match '\[INFO-ALLOC-0001\] Bat dau X\.'
        $content | Should -Not -Match 'Bi bo qua'
    }

    Context 'Khong truyen -CatalogPath -> tu chon dung file theo prefix (log-info/warning/error-messages.json that trong src/config)' {
        It 'Write-InfoLog doc dung src/config/log-info-messages.json' {
            Write-InfoLog -Code 'INFO-ALLOC-0001' -LogDirectory $script:tempLogDir2
            $logFile = Join-Path $script:tempLogDir2 "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
            Get-Content $logFile -Raw | Should -Match '\[INFO-ALLOC-0001\] AllocationWorker bắt đầu chu kỳ\.'
        }

        It 'Write-ErrorLog doc dung src/config/log-error-messages.json' {
            Write-ErrorLog -Code 'ERR-ALLOC-0001' -Parameters @{ ItemId = 'IT-9'; ErrorDetail = 'timeout' } -LogDirectory $script:tempLogDir2
            $logFile = Join-Path $script:tempLogDir2 "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
            Get-Content $logFile -Raw | Should -Match 'Lỗi xử lý item IT-9: timeout'
        }

        It 'Write-InfoLog khong tim thay code chi ton tai trong log-error-messages.json (2 catalog doc lap nhau)' {
            # ERR-ALLOC-0001 chỉ có trong log-error-messages.json — dùng 1 code INFO không tồn tại
            # để xác nhận Write-InfoLog thật sự đọc log-info-messages.json (không phải file khác
            # có sẵn code đó do trùng may rủi), không liên quan gì đến check prefix-mismatch (đã
            # test riêng ở trên).
            { Write-InfoLog -Code 'INFO-ALLOC-9999' -LogDirectory $script:tempLogDir2 } | Should -Throw
        }
    }
}
