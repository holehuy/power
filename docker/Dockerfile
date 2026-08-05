# Dev-toolchain image — CHỈ dùng cho lint/test/viết code (Mac/Windows/Linux như nhau).
# KHÔNG dùng để chạy production Worker: IpamServer/DhcpServer/phần lớn DnsServer cmdlets là
# tính năng Windows Server role thật, không cài rời được, nên không container hoá được (README).
#
# Build:
#   docker compose build
#   (hoặc thẳng: docker build -f docker/Dockerfile -t ipam-dev-toolchain .)
# Dùng nhanh hơn qua Makefile: make build

# .NET 10.0 bắt buộc (không phải lựa chọn) — gói NuGet Microsoft.PowerApps.CLI.Tool hiện chỉ
# đóng gói tools/net10.0/any/, không có bản net8.0 (xác nhận bằng cách tải .nupkg và unzip -l trực tiếp).
FROM mcr.microsoft.com/dotnet/sdk:10.0

ARG PESTER_VERSION=5.6.1
ARG POWERSHELL_VERSION=7.4.6
# Package id xác nhận thật qua NuGet search API (azuresearch-usnc.nuget.org) — tên "Microsoft.PowerPlatform.CLI.Tool"
# ban đầu đoán theo trí nhớ là SAI, không tồn tại trên NuGet.
ARG PAC_CLI_TOOL_ID=Microsoft.PowerApps.CLI.Tool

# PowerShell 7.x — cài bằng binary tar.gz chính thức (phương thức "dotnet tool install --global PowerShell"
# ĐÃ THỬ và THẤT BẠI trong thực tế: gói NuGet "PowerShell" thiếu DotnetToolSettings.xml hợp lệ, không
# phải cách cài cross-platform chính thức như tài liệu cũ mình nhớ nhầm). Xử lý cả amd64 lẫn arm64
# (Apple Silicon build trên OrbStack mặc định là arm64).
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
        amd64) PS_ARCH=x64 ;; \
        arm64) PS_ARCH=arm64 ;; \
        *) echo "Kien truc khong ho tro: $ARCH" >&2 && exit 1 ;; \
    esac && \
    curl -sSL -o /tmp/powershell.tar.gz \
        "https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-${PS_ARCH}.tar.gz" && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -sf /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
    rm /tmp/powershell.tar.gz

# Power Platform CLI (pac) — pack/unpack Power Apps + Power Automate solution (powerplatform/README.md)
RUN dotnet tool install --global ${PAC_CLI_TOOL_ID}

# Python 3.11+ — Worker thu thập ARP (8.1/8.3). Base image (Ubuntu 24.04 "noble" trong
# mcr.microsoft.com/dotnet/sdk:10.0) chỉ có gói python3 (=3.12) trong repo mặc định, không có
# gói python3.11 riêng — cài python3 chung rồi TỰ KIỂM TRA version >= 3.11 thay vì hard-code
# đúng "3.11" (ban đầu giả định sai là Ubuntu luôn có gói python3.11).
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-venv python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -c "import sys; assert sys.version_info >= (3, 11), f'Python {sys.version} < 3.11 (8.1/8.3 yêu cầu 3.11+)'"

# Az CLI — provision Azure VM / Backup vault (infra/bicep)
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# PowerShell module: Pester (unit test), PSScriptAnalyzer (lint bắt buộc, Phụ lục E),
# PnP.PowerShell (provisioning SharePoint list — cross-platform từ v1+, không cần Windows).
#
# LƯU Ý: dòng RUN được bash (shell ngoài) đọc trước khi giao chuỗi cho pwsh, nên $PESTER_VERSION
# (cú pháp bash, KHÔNG phải ${env:PESTER_VERSION} của PowerShell) được bash thay thế thành "5.6.1"
# trước khi pwsh nhận chuỗi lệnh.
RUN pwsh -NoLogo -NoProfile -Command " \
        Set-PSRepository PSGallery -InstallationPolicy Trusted; \
        Install-Module Pester -RequiredVersion $PESTER_VERSION -Force -SkipPublisherCheck; \
        Install-Module PSScriptAnalyzer -Force; \
        Install-Module PnP.PowerShell -Force \
    "

WORKDIR /workspace
CMD ["pwsh"]
