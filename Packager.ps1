##Function Get-Folder
Function Get-Folder($initialDirectory,$Type) {
    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowserDialog.Description = $type
    $FolderBrowserDialog.RootFolder = 'MyComputer'

    # open window to select a Directory, starting with the value of .InitalDirectory
    [void]$FolderBrowserDialog.ShowDialog()     
    
    # returns the value of the selected Path
    return $FolderBrowserDialog.SelectedPath
}
##Function Get-DisplayName
Function Get-DisplayName {
    [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
    [Microsoft.VisualBasic.Interaction]::InputBox("Enter display Name","Display Name?")
}

$tenantID = "##Your Tenant ID xxx.microsoft.com"
Connect-MSIntuneGraph -ClientID ##Add your powershell App ID here -TenantID $tenantID

$Source = (Get-Folder -Type "Choose Source Folder")
$Output = "C:\windows\Temp"
$displayName = Get-DisplayName
$installCommandLine = 'Deploy-Application.exe -DeploymentType "Install"'
$uninstallCommandLine = 'Deploy-Application.exe -DeploymentType "Uninstall"'
$detection = New-IntuneWin32AppDetectionRuleFile -Existence -Path "C:\ProgramData" -FileOrFolder "AutoPackage.txt" -DetectionType exists


$IntuneWinFile = New-IntuneWin32AppPackage -SourceFolder $Source -OutputFolder $Output -SetupFile "Deploy-Application.exe" -Force
Rename-Item -Path ($IntuneWinFile.Path) -NewName "$displayName.intunewin"
$IntuneWinFile.FileName = $displayName

$newIntuneWinPath = (($IntuneWinFile.Path).Trim("Deploy-Application.intunewin"))+"$displayName.intunewin"

Add-IntuneWin32App -FilePath $newIntuneWinPath -DisplayName $displayName -Description "##Add yours" -Publisher "##Add yours" -InstallCommandLine $installCommandLine -UninstallCommandLine $uninstallCommandLine -InstallExperience system -RestartBehavior allow -DetectionRule $detection
