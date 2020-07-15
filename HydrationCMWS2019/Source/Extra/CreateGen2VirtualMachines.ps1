$VMLocation = "C:\VMs"
$VMISO = "C:\HydrationCMWS2019\ISO\HydrationCMWS2019.iso"
$VMNetwork = "New York"

# Check for New York Hyper-V Switch
Write-Host "Checking for Internal Hyper-V Virtual Machine switch"
$VMSwitchNameCheck = Get-VMSwitch | Where-Object -Property Name -EQ "New York"
if ($VMSwitchNameCheck.Name -eq "New York")
        {
        Write-Host "New York Hyper-V switch exist, OK, continuing..." -ForegroundColor Green
        Write-Host ""
        }
Else
        {
        Write-Host "New York Hyper-V switch does not exist. creating it..."
        # Create New York Hyper-V Switch
        Write-host "Creating Internal virtual switch..."
        New-VMSwitch -Name "New York" -SwitchType Internal | Out-Null
        Start-Sleep -Seconds 20
        Write-host "New York virtual switch created" -ForegroundColor Green
        Write-Host ""
        }

# Create DC01
$VMName = "DC01"
$VMMemory = 4096MB
$VMDiskSize = 60GB
New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx"
Set-VMProcessor -VMName $VMName -Count 2
Set-VMDvdDrive -VMName $VMName -Path $VMISO
Start-VM -Name $VMName
VMConnect localhost $VMName

# Create CM01
$VMName = "CM01"
$VMMemory = 16384MB
$VMDiskSize = 300GB
New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx"
Set-VMProcessor -VMName $VMName -Count 4
Set-VMDvdDrive -VMName $VMName -Path $VMISO

# Create MDT01
$VMName = "MDT01"
$VMMemory = 4096MB
$VMDiskSize = 300GB
New-VM -Name $VMName -Generation 2 -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx"
Set-VMDvdDrive -VMName $VMName -Path $VMISO