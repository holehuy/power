# Lab: simulated client network + AD

Dựng lại phần hạ tầng mà **khách hàng** sở hữu trong production (VNet, subnet, AD nội bộ) —
được tham chiếu như "existing" trong [`infra/bicep/main.bicep`](../bicep/main.bicep) nhưng
không được tạo ra ở đó. Dùng bộ này để test toàn bộ luồng: tạo VM worker → join domain, giống
hệt README.md §5.1 ở gốc repo, mà không cần mạng khách hàng thật.

**Chỉ dùng cho lab/test. Không deploy vào subscription production hay dùng domain name thật.**

## Kiến trúc

```
resource group (lab)
├── vnet-lab-client (10.10.0.0/16)
│   └── snet-lab-client (10.10.1.0/24), DNS → vm-lab-dc-01
│       ├── vm-lab-dc-01           AD DS forest root + DNS (dựng bởi bộ này)
│       └── vm-ipam-worker-01      VM vendor deploy (infra/bicep/main.bicep, join domain sau)
```

## Bước 1 — Deploy lab (VNet + AD DC)

```bash
az group create --name rg-lab-client --location japaneast

MY_IP=$(curl -s ifconfig.me)/32

# Optional: validate syntax + preview what will be created before deploying, same as
# the vendor flow in ../bicep — see README.md § "Validate before deploying".
az bicep build --file infra/lab/main.bicep --stdout > /dev/null
az deployment group what-if \
  --resource-group rg-lab-client \
  --template-file infra/lab/main.bicep \
  --parameters allowedRdpSourceIp="$MY_IP"

az deployment group create \
  --name lab-client-infra \
  --resource-group rg-lab-client \
  --template-file infra/lab/main.bicep \
  --parameters allowedRdpSourceIp="$MY_IP"
```

`adminPassword` và `safeModeAdministratorPassword` là `@secure()`, không có default — Azure CLI
sẽ prompt nhập ẩn. **Không** truyền qua `--parameters adminPassword=...` (lưu vào shell history).

Deployment tạo VM DC và chạy Run Command để `Install-ADDSForest`. Script tự lên lịch reboot sau
60 giây để hoàn tất promotion — `az deployment group create` sẽ trả về **trước khi VM reboot
xong**, nên đợi thêm khoảng **5-10 phút** trước khi qua bước tiếp theo.

Kiểm tra AD đã lên chưa (RDP vào `dcPublicIp` bằng `adminUsername`/`adminPassword`, hoặc):

```bash
az vm run-command invoke \
  --resource-group rg-lab-client --name vm-lab-dc-01 \
  --command-id RunPowerShellScript \
  --scripts "Get-ADDomain | Select-Object DNSRoot, DomainMode"
```

Thành công khi lệnh trên trả về domain thay vì lỗi "not recognized" (nghĩa là AD DS đã sẵn sàng).

## Bước 2 — Lấy subnet ID để feed vào phần vendor

```bash
az deployment group show \
  --resource-group rg-lab-client --name lab-client-infra \
  --query properties.outputs.subnetId.value -o tsv
```

## Bước 3 — Deploy VM vendor vào subnet lab (đúng flow production thật)

Theo README.md gốc, mục "Infrastructure Deployment":

```bash
az group create --name rg-vendor-lab --location japaneast

az deployment group create \
  --name ipam-worker-infra \
  --resource-group rg-vendor-lab \
  --template-file infra/bicep/main.bicep \
  --parameters existingSubnetId=<subnet-id-từ-bước-2>
```

## Bước 4 — Join domain

RDP vào `vm-ipam-worker-01`, làm đúng README.md §5.1:

```powershell
Add-Computer -DomainName "lab.local" `
  -Credential (Get-Credential) `
  -Restart
```

Khi `Get-Credential` hỏi, nhập `labadmin` (hoặc `LAB\labadmin`) và `adminPassword` đã dùng ở
Bước 1 — sau khi forest được tạo mới, account local admin ban đầu trở thành Domain
Administrator với cùng password.

## Dọn dẹp

```bash
az group delete --name rg-vendor-lab --yes --no-wait
az group delete --name rg-lab-client --yes --no-wait
```
