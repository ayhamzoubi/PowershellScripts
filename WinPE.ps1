# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Please start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}

#------------------------------------------------------------------------------------------

# Settings variables
$WinPE_BuildFolder = "C:\WinPE\WinPE_x64"
$WinPE_Architecture = "amd64"
$WinPE_MountFolder = "C:\WinPE\Mount"
$WinPE_Drivers = "C:\WinPE\Files\Drivers"
$winPE_Scripts = "C:\WinPE\Files\Scripts"

$ADK_Path = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit"
$WinPE_ADK_Path = $ADK_Path + "\Windows Preinstallation Environment"
$WinPE_OCs_Path = $WinPE_ADK_Path + "\$WinPE_Architecture\WinPE_OCs"
$Sv_WinPE_OCs_Path = $WinPE_OCs_Path + "\sv-se"
$DISM_Path = $ADK_Path + "\Deployment Tools" + "\$WinPE_Architecture\DISM"
$OSCDIMG_Path = $ADK_Path + "\Deployment Tools" + "\$WinPE_Architecture\Oscdimg"

# Packages To install
$WinPEPackage = @(
"WinPE-HTA.cab",
"WinPE-MDAC.cab",
"WinPE-NetFx.cab",
"WinPE-PowerShell.cab",
"WinPE-WMI.cab",
"WinPE-Scripting.cab",
"WinPE-WDS-Tools.cab",
"WinPE-SecureStartup.cab",
"WinPE-Dot3Svc.cab"
"WinPE-StorageWMI.cab"
)

$WinPEPackage_sv =  @(
"WinPE-HTA_sv-se.cab",
"WinPE-MDAC_sv-se.cab",
"WinPE-NetFx_sv-se.cab",
"WinPE-PowerShell_sv-se.cab",
"WinPE-WMI_sv-se.cab",
"WinPE-Scripting_sv-se.cab",
"WinPE-WDS-Tools_sv-se.cab",
"WinPE-SecureStartup_sv-se.cab",
"WinPE-Dot3Svc_sv-se.cab"
"WinPE-StorageWMI_sv-se.cab"
)

#------------------------------------------------------------------------------------------

# Delete existing WinPE folder (if exist)
try 
{
if (Test-Path -path $WinPE_BuildFolder) {Remove-Item -Path $WinPE_BuildFolder -Recurse -ErrorAction Stop}
}
catch
{
    Write-Warning "Error..."
    Write-Warning "An existing WIM still mounted, use DISM /Cleanup-Wim to clean up and run script again"
    Break
}
# Check for existing folder
if (Test-Path -path "$WinPE_BuildFolder") { Write-Warning "Folder exist, delete it"; Break}

# Copy WinPE boot image & WinPE image files.
Write-Host "Copying WinPE Files...." -ForegroundColor Green
if ( -Not (Test-Path -path "$WinPE_BuildFolder\Sources")) {New-Item "$WinPE_BuildFolder\Sources" -Type Directory | Out-Null} 
Copy-Item "$WinPE_ADK_Path\$WinPE_Architecture\en-us\winpe.wim" "$WinPE_BuildFolder\Sources\boot.wim"
Copy-Item "$WinPE_ADK_Path\$WinPE_Architecture\Media\*" "$WinPE_BuildFolder" -Recurse

# Mount the WinPE image
Write-Host "Mounting WinPE image..." -ForegroundColor Green
$WimFile = "$WinPE_BuildFolder\Sources\boot.wim"
Mount-WindowsImage -ImagePath $WimFile -Path $WinPE_MountFolder -Index 1 | Out-Null

#Add drivers
Write-Host "Adding drivers..." -ForegroundColor Green
Add-WindowsDriver –Path $WinPE_MountFolder -Driver $WinPE_Drivers -Recurse | Out-Null

#Add Packages
Write-Host "Adding WinPE Packages..." -ForegroundColor Green
 
Foreach ($Package in $WinPEPackage){
Write-Host "Importing $Package" -ForegroundColor Green
Add-WindowsPackage –Path $WinPE_MountFolder -PackagePath $WinPE_OCs_Path\$Package | Out-Null
}

Foreach ($Package in $WinPEPackage_sv){
Write-Host "Importing $Package" -ForegroundColor Green
Add-WindowsPackage –Path $WinPE_MountFolder -PackagePath $Sv_WinPE_OCs_Path\$Package | Out-Null
}

#Add DaRT to the boot image
Write-Host "Importing DaRT to boot image..." -ForegroundColor Green
expand.exe "C:\WinPE\Files\Dart\Toolsx64.cab" -F:*.* $WinPE_MountFolder | Out-Null
Copy-Item "C:\WinPE\Files\Dart\DartConfig8.dat" $WinPE_MountFolder\Windows\System32\DartConfig.dat

#Set locale
Write-Host "Setting locale..." -ForegroundColor Green
Dism /Image:$WinPE_MountFolder /Set-SysLocale:sv-SE
Dism /Image:$WinPE_MountFolder /Set-UserLocale:sv-SE
Dism /Image:$WinPE_MountFolder /Set-InputLocale:sv-SE
Dism /image:$WinPE_MountFolder /Set-TimeZone:"W. Europe Standard Time"

#Add CMtrace and DiskPart and missing files for WPF
Copy-Item "C:\WinPE\Files\cmtrace.exe" $WinPE_MountFolder\Windows\System32\cmtrace.exe
#Copy-Item "C:\WinPE\Files\Scripts\Diskpart.cmd" $WinPE_MountFolder\Windows\System32\Diskpart.cmd
Copy-item "C:\WinPE\Files\BCP47Langs.dll" $WinPE_MountFolder\Windows\System32\BCP47Langs.dll
Copy-item "C:\WinPE\Files\BCP47mrm.dll" $WinPE_MountFolder\Windows\System32\BCP47mrm.dll

#Add AD PowerShell module
Set-Location -Path $winPE_Scripts
.\AddADPowerShellModule.ps1 -sourceWinDir $ENV:windir -destinationWinDir $WinPE_MountFolder | Out-Null

Dismount-WindowsImage -Path $WinPE_MountFolder -Save
