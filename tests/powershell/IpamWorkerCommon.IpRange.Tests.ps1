#Requires -Modules Pester
<#
    Test cho các hàm IP/CIDR/dải tĩnh trong IpamWorkerCommon.psm1 — dùng chung bởi
    reflect-to-ipam (7.3) và (tương lai) auto-deletion-worker (7.4-3, "IP không thuộc bất kỳ
    IPAM range nào"). Sai công thức ở đây có nghĩa là ARP tự động đăng ký nhầm IP thuộc dynamic
    pool, hoặc auto-deletion-worker đánh giá xóa nhầm IP ngoài phạm vi — rủi ro cao, test kỹ.
#>

BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\workers\common\IpamWorkerCommon.psm1" -Force
}

Describe 'ConvertTo-UInt32IpAddress' {
    It 'Chuyển đúng IP về uint32 (big-endian)' {
        ConvertTo-UInt32IpAddress -IpAddress '10.0.0.1' | Should -Be 167772161
        ConvertTo-UInt32IpAddress -IpAddress '0.0.0.0' | Should -Be 0
        ConvertTo-UInt32IpAddress -IpAddress '255.255.255.255' | Should -Be 4294967295
    }
}

Describe 'Test-IpAddressInCidr' {
    It 'Nhận diện đúng IP trong CIDR' {
        Test-IpAddressInCidr -IpAddress '10.11.20.55' -Cidr '10.11.20.0/24' | Should -BeTrue
    }

    It 'Loại đúng IP ngoài CIDR' {
        Test-IpAddressInCidr -IpAddress '10.11.21.5' -Cidr '10.11.20.0/24' | Should -BeFalse
    }

    It 'Biên đúng ở /32 (chỉ khớp đúng 1 IP)' {
        Test-IpAddressInCidr -IpAddress '10.0.0.5' -Cidr '10.0.0.5/32' | Should -BeTrue
        Test-IpAddressInCidr -IpAddress '10.0.0.6' -Cidr '10.0.0.5/32' | Should -BeFalse
    }

    It 'Biên đúng ở /0 (khớp mọi IP)' {
        Test-IpAddressInCidr -IpAddress '8.8.8.8' -Cidr '0.0.0.0/0' | Should -BeTrue
    }
}

Describe 'Test-IpAddressInRange' {
    It 'Nhận diện đúng IP trong khoảng [start, end] kể cả 2 đầu mút' {
        Test-IpAddressInRange -IpAddress '10.0.0.100' -RangeStart '10.0.0.100' -RangeEnd '10.0.0.200' | Should -BeTrue
        Test-IpAddressInRange -IpAddress '10.0.0.200' -RangeStart '10.0.0.100' -RangeEnd '10.0.0.200' | Should -BeTrue
        Test-IpAddressInRange -IpAddress '10.0.0.150' -RangeStart '10.0.0.100' -RangeEnd '10.0.0.200' | Should -BeTrue
    }

    It 'Loại đúng IP ngoài khoảng' {
        Test-IpAddressInRange -IpAddress '10.0.0.99' -RangeStart '10.0.0.100' -RangeEnd '10.0.0.200' | Should -BeFalse
        Test-IpAddressInRange -IpAddress '10.0.0.201' -RangeStart '10.0.0.100' -RangeEnd '10.0.0.200' | Should -BeFalse
    }
}

Describe 'ConvertFrom-StaticIpRangeRaw' {
    It 'Parse đúng mảng nhiều dải rời rạc (6.3: "hỗ trợ nhiều dải")' {
        $raw = '[{"start":"10.0.0.10","end":"10.0.0.20"},{"start":"10.0.1.10","end":"10.0.1.20"}]'
        $ranges = ConvertFrom-StaticIpRangeRaw -Raw $raw
        $ranges.Count | Should -Be 2
        $ranges[0].start | Should -Be '10.0.0.10'
        $ranges[1].end | Should -Be '10.0.1.20'
    }

    It 'Trả về mảng rỗng khi giá trị trống (chưa đồng bộ lần nào)' {
        (ConvertFrom-StaticIpRangeRaw -Raw '').Count | Should -Be 0
        (ConvertFrom-StaticIpRangeRaw -Raw $null).Count | Should -Be 0
    }
}

Describe 'Test-IpAddressInStaticRange — quy tắc phân loại đầu 7.3' {
    It 'DhcpScopeExists=true: dùng StaticIpRangeRaw, KHÔNG dùng CIDR (CIDR còn chứa cả dynamic pool)' {
        $segment = [PSCustomObject]@{
            CIDR             = '10.0.0.0/24'
            DhcpScopeExists  = $true
            StaticIpRangeRaw = '[{"start":"10.0.0.200","end":"10.0.0.250"}]'
        }
        # Trong CIDR nhưng NGOÀI dải cố định (thuộc dynamic pool giả định .1-.199) -> phải bị loại.
        Test-IpAddressInStaticRange -IpAddress '10.0.0.50' -Segment $segment | Should -BeFalse
        # Trong dải cố định thật sự -> phải nhận.
        Test-IpAddressInStaticRange -IpAddress '10.0.0.210' -Segment $segment | Should -BeTrue
    }

    It 'DhcpScopeExists=false: dùng toàn bộ CIDR làm dải cố định (3.1/7.3 mở đầu)' {
        $segment = [PSCustomObject]@{
            CIDR             = '10.1.0.0/24'
            DhcpScopeExists  = $false
            StaticIpRangeRaw = ''
        }
        Test-IpAddressInStaticRange -IpAddress '10.1.0.5' -Segment $segment | Should -BeTrue
        Test-IpAddressInStaticRange -IpAddress '10.2.0.5' -Segment $segment | Should -BeFalse
    }
}
