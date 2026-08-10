#Requires -Modules Pester
<#
    Test cho NotificationClient.psm1: Get-NotificationTemplate (parse file template) và
    Send-TemplatedAlert (nối với Expand-MessageTemplate của Common.psm1 + gửi mail). Test cho
    Expand-MessageTemplate nằm ở Common.Tests.ps1 (hàm này sống ở Common.psm1, dùng chung với
    Write-InfoLog/-WarningLog/-ErrorLog — không test lặp lại ở đây). Send-MailMessage KHÔNG được gọi
    thật — mock ở mọi test (test không có SMTP relay thật).
#>

BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\common\Common.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\common\NotificationClient.psm1" -Force
    $script:tempTemplateDir = Join-Path ([System.IO.Path]::GetTempPath()) "templates-test-$(New-Guid)"
    New-Item -ItemType Directory -Path $script:tempTemplateDir -Force | Out-Null
}

AfterAll {
    Remove-Item $script:tempTemplateDir -Recurse -ErrorAction SilentlyContinue
}

Describe 'Get-NotificationTemplate' {

    It 'Parse dung Subject/Body tu file .txt, IsHtml=false' {
        Set-Content -Path (Join-Path $script:tempTemplateDir 'T1.txt') -Value @'
Subject: Test {{Name}}
---
Xin chao {{Name}}, day la noi dung.
'@
        $result = Get-NotificationTemplate -TemplateName 'T1' -TemplateDirectory $script:tempTemplateDir
        $result.Subject | Should -Be 'Test {{Name}}'
        $result.Body | Should -Be 'Xin chao {{Name}}, day la noi dung.'
        $result.IsHtml | Should -Be $false
    }

    It 'IsHtml=true khi duoi file la .html' {
        Set-Content -Path (Join-Path $script:tempTemplateDir 'T2.html') -Value @'
Subject: HTML {{Name}}
---
<p>Xin chao {{Name}}</p>
'@
        $result = Get-NotificationTemplate -TemplateName 'T2' -TemplateDirectory $script:tempTemplateDir
        $result.IsHtml | Should -Be $true
        $result.Body | Should -Be '<p>Xin chao {{Name}}</p>'
    }

    It 'Throw khi khong tim thay template' {
        { Get-NotificationTemplate -TemplateName 'KhongTonTai' -TemplateDirectory $script:tempTemplateDir } | Should -Throw
    }

    It 'Throw khi file thieu dong phan cach ---' {
        Set-Content -Path (Join-Path $script:tempTemplateDir 'T3.txt') -Value "Subject: Test`nKhong co phan cach"
        { Get-NotificationTemplate -TemplateName 'T3' -TemplateDirectory $script:tempTemplateDir } | Should -Throw
    }

    It 'Throw khi thieu dong Subject hop le' {
        Set-Content -Path (Join-Path $script:tempTemplateDir 'T4.txt') -Value "Khong co Subject`n---`nBody"
        { Get-NotificationTemplate -TemplateName 'T4' -TemplateDirectory $script:tempTemplateDir } | Should -Throw
    }
}

Describe 'Send-TemplatedAlert' {

    BeforeEach {
        Mock Send-InternalAlert -ModuleName NotificationClient {}
        Set-Content -Path (Join-Path $script:tempTemplateDir 'F99-test.txt') -Value @'
Subject: [IPAM-Worker] Test {{IpAddress}}
---
Noi dung ve IP {{IpAddress}}.
'@
    }

    It 'Goi Send-InternalAlert voi Subject/Body da thay token, BodyAsHtml=false' {
        Send-TemplatedAlert -TemplateName 'F99-test' -Parameters @{ IpAddress = '10.0.0.99' } -TemplateDirectory $script:tempTemplateDir
        Should -Invoke Send-InternalAlert -ModuleName NotificationClient -Times 1 -ParameterFilter {
            $Subject -eq '[IPAM-Worker] Test 10.0.0.99' -and
            $Body -eq 'Noi dung ve IP 10.0.0.99.' -and
            $BodyAsHtml -eq $false
        }
    }

    It 'BodyAsHtml=true khi template la .html' {
        Set-Content -Path (Join-Path $script:tempTemplateDir 'F98-html-test.html') -Value @'
Subject: HTML {{IpAddress}}
---
<p>{{IpAddress}}</p>
'@
        Send-TemplatedAlert -TemplateName 'F98-html-test' -Parameters @{ IpAddress = '10.0.0.1' } -TemplateDirectory $script:tempTemplateDir
        Should -Invoke Send-InternalAlert -ModuleName NotificationClient -Times 1 -ParameterFilter { $BodyAsHtml -eq $true }
    }
}
