<#
.Synopsis
    Sample script for Hydration Kit
.DESCRIPTION
    Created: 2019-10-13
    Version: 1.0

    Author : Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com

    Disclaimer: This script is provided "AS IS" with no warranties, confers no rights and 
    is not supported by the author or DeploymentArtist..
.EXAMPLE
    NA
#>


# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
	Write-Warning "Aborting script..."
    Break
}

# Verify that MDT 8456 is installed
if (!((Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Microsoft Deployment Toolkit (6.3.8456.1000)"}).Displayname).count) {Write-Warning "MDT 8456 not installed, aborting...";Break}

# Verify that Windows ADK 10 is installed 
if (!((Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Windows Assessment and Deployment Kit - Windows 10"}).Displayname).count) {Write-Warning "Windows ADK 10 is not installed, aborting...";Break}

# Validation, verify that the deployment share doesnt exist already
$RootDrive = "C:"
If (Get-SmbShare | Where-Object { $_.Name -eq "HydrationCMWS2019$"}){Write-Warning "HydrationCMWS2019$ share already exist, please cleanup and try again. Aborting...";Break}
if (Test-Path -Path "$RootDrive\HydrationCMWS2019\DS") {Write-Warning "$RootDrive\HydrationCMWS2019\DS already exist, please cleanup and try again. Aborting...";Break}
if (Test-Path -Path "$RootDrive\HydrationCMWS2019\ISO") {Write-Warning "$RootDrive\HydrationCMWS2019\ISO already exist, please cleanup and try again. Aborting...";Break}

# Validation, verify that the PSDrive doesnt exist already
if (Test-Path -Path "DS001:") {Write-Warning "DS001: PSDrive already exist, please cleanup and try again. Aborting...";Break}

# Check free space on C: - Minimum for the Hydration Kit is 50 GB
$NeededFreeSpace = 50 #GigaBytes
$Disk = Get-wmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" 
$FreeSpace = [MATH]::ROUND($disk.FreeSpace /1GB)
Write-Host "Checking free space on C: - Minimum is $NeededFreeSpace GB"

if($FreeSpace -lt $NeededFreeSpace){
    
    Write-Warning "Oupps, you need at least $NeededFreeSpace GB of free disk space"
    Write-Warning "Available free space on C: is $FreeSpace GB"
    Write-Warning "Aborting script..."
    Write-Host ""
    Write-Host "TIP: If you don't have space on C: but have other volumes, say D:, available, " -ForegroundColor Yellow
    Write-Host "then copy the HydrationCMWS2019 folder to D: and use mklink to create a synlink on C:" -ForegroundColor Yellow
    Write-Host "The syntax is: mklink C:\HydrationCMWS2019 D:\HydrationCMWS2019 /D" -ForegroundColor Yellow
    Break
}

# Validation OK, create Hydration Deployment Share
$MDTServer = (get-wmiobject win32_computersystem).Name

Add-PSSnapIn Microsoft.BDD.PSSnapIn -ErrorAction SilentlyContinue 
md C:\HydrationCMWS2019\DS
new-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root "C:\HydrationCMWS2019\DS" -Description "Hydration ConfigMgr" -NetworkPath "\\$MDTServer\HydrationCMWS2019$" | add-MDTPersistentDrive
New-SmbShare –Name HydrationCMWS2019$ –Path "C:\HydrationCMWS2019\DS"  –ChangeAccess EVERYONE

md C:\HydrationCMWS2019\ISO\Content\Deploy
new-item -path "DS001:\Media" -enable "True" -Name "MEDIA001" -Comments "" -Root "C:\HydrationCMWS2019\ISO" -SelectionProfile "Everything" -SupportX86 "False" -SupportX64 "True" -GenerateISO "True" -ISOName "HydrationCMWS2019.iso"
new-PSDrive -Name "MEDIA001" -PSProvider "MDTProvider" -Root "C:\HydrationCMWS2019\ISO\Content\Deploy" -Description "Hydration ConfigMgr Media" -Force

# Configure MEDIA001 Settings (disable MDAC) - Not needed in the Hydration Kit
Set-ItemProperty -Path MEDIA001: -Name Boot.x86.FeaturePacks -Value ""
Set-ItemProperty -Path MEDIA001: -Name Boot.x64.FeaturePacks -Value ""

# Copy sample files to Hydration Deployment Share
Copy-Item -Path "C:\HydrationCMWS2019\Source\Hydration\Applications" -Destination "C:\HydrationCMWS2019\DS" -Recurse -Force
Copy-Item -Path "C:\HydrationCMWS2019\Source\Hydration\Control" -Destination "C:\HydrationCMWS2019\DS" -Recurse -Force
Copy-Item -Path "C:\HydrationCMWS2019\Source\Hydration\Operating Systems" -Destination "C:\HydrationCMWS2019\DS" -Recurse -Force
Copy-Item -Path "C:\HydrationCMWS2019\Source\Hydration\Scripts" -Destination "C:\HydrationCMWS2019\DS" -Recurse -Force
Copy-Item -Path "C:\HydrationCMWS2019\Source\Media\Control" -Destination "C:\HydrationCMWS2019\ISO\Content\Deploy" -Recurse -Force
