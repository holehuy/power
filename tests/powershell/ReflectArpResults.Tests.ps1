#Requires -Modules Pester
<#
    Test cho Invoke-ArpReflection (7.3) — logic phân nhánh (a)/(b)/(c) + đối chiếu MAC bên trong
    Invoke-ReflectArpResults.ps1. Toàn bộ cmdlet IPAM thật (Get-/Add-/Set-IpamAddress) được stub +
    Mock vì môi trường test không có IpamServer feature (Docker dev-toolchain Linux/Mac — xem
    README.md "Limitation: production workers cannot be containerized"). Get-SharePointListItems
    không được gọi trong các test này (chỉ gọi ở entry-point cấp script, nằm ngoài guard dot-source).
#>

BeforeAll {
    # Stub trước cho cmdlet IPAM thật (chỉ tồn tại trên Windows Server đã cài IpamServer) — định
    # nghĩa trước để Pester Mock có function cụ thể để ghi đè, không phụ thuộc máy chạy test.
    function Get-IpamAddress { param($IpAddress) }
    function Add-IpamAddress { param($IpAddress, $MacAddress, $CustomField) }
    function Set-IpamAddress { param($IpAddress, $MacAddress, $Source, $CustomField) }

    Import-Module "$PSScriptRoot\..\..\src\workers\common\IpamWorkerCommon.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\workers\common\NotificationClient.psm1" -Force
    # Dot-source (không execute entry-point) — xem guard $MyInvocation.InvocationName trong file.
    . "$PSScriptRoot\..\..\src\arp-collector\reflect-to-ipam\Invoke-ReflectArpResults.ps1"
}

Describe 'Invoke-ArpReflection (7.3) — phân nhánh theo IP' {

    BeforeEach {
        Mock Write-WorkerLog {}
        Mock Send-InternalAlert {}
        Mock Enter-IpEntryMutex { [System.Threading.Mutex]::new() }
        Mock Exit-IpEntryMutex {}
    }

    $segmentWithScope = [PSCustomObject]@{
        SegmentName        = 'Test - co DHCP scope'
        CIDR               = '10.0.0.0/24'
        DhcpScopeExists    = $true
        StaticIpRangeRaw   = '[{"start":"10.0.0.100","end":"10.0.0.200"}]'
        IsActive           = $true
        RangeChangePending = $false
    }
    $segmentNoScope = [PSCustomObject]@{
        SegmentName        = 'Test - khong DHCP scope'
        CIDR               = '10.1.0.0/24'
        DhcpScopeExists    = $false
        StaticIpRangeRaw   = ''
        IsActive           = $true
        RangeChangePending = $false
    }

    It 'IP trong dynamic pool (ngoai StaticIpRangeRaw) bi bo qua, khong goi Add/Set-IpamAddress' {
        Mock Get-IpamAddress {}
        $entries = @([PSCustomObject]@{ ip_address = '10.0.0.50'; mac_address = 'aa:bb:cc:dd:ee:01'; observed_at = '2026-08-05T03:00:00+00:00' })

        Invoke-ArpReflection -ArpEntries $entries -SegmentsSnapshot @($segmentWithScope) | Should -Be 0
        Should -Invoke Add-IpamAddress -Times 0
        Should -Invoke Set-IpamAddress -Times 0
    }

    It '(c) IP chua dang ky, segment IsActive=true & RangeChangePending=false -> Add-IpamAddress Source=AutoDetected' {
        Mock Get-IpamAddress { $null }
        Mock Add-IpamAddress {}
        $entries = @([PSCustomObject]@{ ip_address = '10.0.0.150'; mac_address = 'aa:bb:cc:dd:ee:02'; observed_at = '2026-08-05T03:00:00+00:00' })

        Invoke-ArpReflection -ArpEntries $entries -SegmentsSnapshot @($segmentWithScope) | Should -Be 1
        Should -Invoke Add-IpamAddress -Times 1 -ParameterFilter {
            $IpAddress -eq '10.0.0.150' -and $CustomField.Source -eq 'AutoDetected'
        }
    }

    It '(c) giu lai (KHONG dang ky) khi segment RangeChangePending=true' {
        Mock Get-IpamAddress { $null }
        Mock Add-IpamAddress {}
        $pendingSegment = [PSCustomObject]@{
            SegmentName        = $segmentWithScope.SegmentName
            CIDR               = $segmentWithScope.CIDR
            DhcpScopeExists    = $segmentWithScope.DhcpScopeExists
            StaticIpRangeRaw   = $segmentWithScope.StaticIpRangeRaw
            IsActive           = $true
            RangeChangePending = $true
        }
        $entries = @([PSCustomObject]@{ ip_address = '10.0.0.150'; mac_address = 'aa:bb:cc:dd:ee:02'; observed_at = '2026-08-05T03:00:00+00:00' })

        Invoke-ArpReflection -ArpEntries $entries -SegmentsSnapshot @($pendingSegment) | Should -Be 0
        Should -Invoke Add-IpamAddress -Times 0
    }

    It '(c) giu lai (KHONG dang ky) khi segment IsActive=false' {
        Mock Get-IpamAddress { $null }
        Mock Add-IpamAddress {}
        $inactiveSegment = [PSCustomObject]@{
            SegmentName        = $segmentWithScope.SegmentName
            CIDR               = $segmentWithScope.CIDR
            DhcpScopeExists    = $segmentWithScope.DhcpScopeExists
            StaticIpRangeRaw   = $segmentWithScope.StaticIpRangeRaw
            IsActive           = $false
            RangeChangePending = $false
        }
        $entries = @([PSCustomObject]@{ ip_address = '10.0.0.150'; mac_address = 'aa:bb:cc:dd:ee:02'; observed_at = '2026-08-05T03:00:00+00:00' })

        Invoke-ArpReflection -ArpEntries $entries -SegmentsSnapshot @($inactiveSegment) | Should -Be 0
        Should -Invoke Add-IpamAddress -Times 0
    }

    It '(a) da dang ky + Source chua Cooldown -> khoi phuc AutoDetected, gui thong bao F#14 khi goc co Requested' {
        Mock Get-IpamAddress {
            [PSCustomObject]@{
                IpAddress  = '10.0.0.150'
                Source     = @('Requested', 'Cooldown')
                MacAddress = 'aa:bb:cc:dd:ee:99'
                LastSeenAt = '2026-06-01T00:00:00+09:00'
            }
        }
        Mock Set-IpamAddress {}
        $entries = @([PSCustomObject]@{ ip_address = '10.0.0.150'; mac_address = 'aa:bb:cc:dd:ee:99'; observed_at = '2026-08-05T03:00:00+00:00' })

        Invoke-ArpReflection -ArpEntries $entries -SegmentsSnapshot @($segmentWithScope) | Should -Be 1

        Should -Invoke Set-IpamAddress -Times 1 -ParameterFilter { $CustomField -and $CustomField.ContainsKey('Source') -and $CustomField.Source -eq 'AutoDetected' }
        Should -Invoke Set-IpamAddress -Times 1 -ParameterFilter { $CustomField -and $CustomField.ContainsKey('CooldownStartedAt') -and $null -eq $CustomField.CooldownStartedAt }
        Should -Invoke Set-IpamAddress -Times 1 -ParameterFilter { $CustomField -and $CustomField.ContainsKey('RequestId') -and $null -eq $CustomField.RequestId }
        Should -Invoke Send-InternalAlert -Times 1
    }

    It '(a) khoi phuc khi Source goc KHONG co Requested -> khong gui thong bao F#14' {
        Mock Get-IpamAddress {
            [PSCustomObject]@{
                IpAddress  = '10.0.0.150'
                Source     = @('AutoDetected', 'Cooldown')
                MacAddress = 'aa:bb:cc:dd:ee:99'
                LastSeenAt = '2026-06-01T00:00:00+09:00'
            }
        }
        Mock Set-IpamAddress {}
        $entries = @([PSCustomObject]@{ ip_address = '10.0.0.150'; mac_address = 'aa:bb:cc:dd:ee:99'; observed_at = '2026-08-05T03:00:00+00:00' })

        Invoke-ArpReflection -ArpEntries $entries -SegmentsSnapshot @($segmentWithScope) | Should -Be 1
        Should -Invoke Send-InternalAlert -Times 0
    }

    It '(b) da dang ky khong Cooldown, LastSeenAt < 24h truoc -> KHONG cap nhat LastSeenAt' {
        Mock Get-IpamAddress {
            [PSCustomObject]@{
                IpAddress  = '10.0.0.150'
                Source     = @('Requested')
                MacAddress = 'aa:bb:cc:dd:ee:99'
                LastSeenAt = '2026-08-05T11:00:00+09:00'  # 2 gio truoc observed_at (JST 13:00)
            }
        }
        Mock Set-IpamAddress {}
        $entries = @([PSCustomObject]@{ ip_address = '10.0.0.150'; mac_address = 'aa:bb:cc:dd:ee:99'; observed_at = '2026-08-05T04:00:00+00:00' })

        Invoke-ArpReflection -ArpEntries $entries -SegmentsSnapshot @($segmentWithScope) | Should -Be 1
        Should -Invoke Set-IpamAddress -Times 0 -ParameterFilter { $CustomField -and $CustomField.ContainsKey('LastSeenAt') }
    }

    It '(b) da dang ky khong Cooldown, LastSeenAt >= 24h truoc -> cap nhat LastSeenAt' {
        Mock Get-IpamAddress {
            [PSCustomObject]@{
                IpAddress  = '10.0.0.150'
                Source     = @('Requested')
                MacAddress = 'aa:bb:cc:dd:ee:99'
                LastSeenAt = '2026-08-03T13:00:00+09:00'  # > 24h truoc
            }
        }
        Mock Set-IpamAddress {}
        $entries = @([PSCustomObject]@{ ip_address = '10.0.0.150'; mac_address = 'aa:bb:cc:dd:ee:99'; observed_at = '2026-08-05T04:00:00+00:00' })

        Invoke-ArpReflection -ArpEntries $entries -SegmentsSnapshot @($segmentWithScope) | Should -Be 1
        Should -Invoke Set-IpamAddress -Times 1 -ParameterFilter { $CustomField -and $CustomField.ContainsKey('LastSeenAt') }
    }

    It 'MAC khac nhau tren IP Source=Requested -> ghi de MAC + gui thong bao nghi ngo xung dot (F#13)' {
        Mock Get-IpamAddress {
            [PSCustomObject]@{
                IpAddress  = '10.0.0.150'
                Source     = @('Requested')
                MacAddress = 'aa:aa:aa:aa:aa:aa'
                LastSeenAt = '2026-08-03T13:00:00+09:00'
            }
        }
        Mock Set-IpamAddress {}
        $entries = @([PSCustomObject]@{ ip_address = '10.0.0.150'; mac_address = 'bb:bb:bb:bb:bb:bb'; observed_at = '2026-08-05T04:00:00+00:00' })

        Invoke-ArpReflection -ArpEntries $entries -SegmentsSnapshot @($segmentWithScope) | Should -Be 1
        Should -Invoke Set-IpamAddress -Times 1 -ParameterFilter { $MacAddress -eq 'bb:bb:bb:bb:bb:bb' }
        Should -Invoke Send-InternalAlert -Times 1
    }

    It 'MAC khac nhau tren IP Source=AutoDetected -> ghi de MAC nhung KHONG thong bao' {
        Mock Get-IpamAddress {
            [PSCustomObject]@{
                IpAddress  = '10.0.0.150'
                Source     = @('AutoDetected')
                MacAddress = 'aa:aa:aa:aa:aa:aa'
                LastSeenAt = '2026-08-03T13:00:00+09:00'
            }
        }
        Mock Set-IpamAddress {}
        $entries = @([PSCustomObject]@{ ip_address = '10.0.0.150'; mac_address = 'bb:bb:bb:bb:bb:bb'; observed_at = '2026-08-05T04:00:00+00:00' })

        Invoke-ArpReflection -ArpEntries $entries -SegmentsSnapshot @($segmentWithScope) | Should -Be 1
        Should -Invoke Send-InternalAlert -Times 0
    }

    It 'Segment DhcpScopeExists=false: dung toan bo CIDR lam dai co dinh' {
        Mock Get-IpamAddress { $null }
        Mock Add-IpamAddress {}
        $entries = @([PSCustomObject]@{ ip_address = '10.1.0.50'; mac_address = 'aa:bb:cc:dd:ee:03'; observed_at = '2026-08-05T03:00:00+00:00' })

        Invoke-ArpReflection -ArpEntries $entries -SegmentsSnapshot @($segmentNoScope) | Should -Be 1
        Should -Invoke Add-IpamAddress -Times 1
    }
}
