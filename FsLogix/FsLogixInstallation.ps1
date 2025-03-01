###################################################
#    FSLogix Setup Installation Script   #
#    Written by Aavisek Choudhury
###################################################

$StartTime = Get-Date
Write-Output "Starting FSLogix Installation for AVD Image Preparation"

# Define Variables
$LocalAVDPath = "C:\temp\avd\"
$FSLogixDownloadURL = "https://aka.ms/fslogix_download"  # Ensure this is up-to-date
$FSInstallerZip = "$LocalAVDPath\FSLogixAppsSetup.zip"
$FSInstallerPath = "$LocalAVDPath\FSLogix"

# Create Necessary Directories
If (!(Test-Path $LocalAVDPath)) {
    New-Item -Path $LocalAVDPath -ItemType Directory -Force | Out-Null
}

# Download FSLogix
Try {
    Write-Output "Downloading FSLogix..."
    Invoke-WebRequest -Uri $FSLogixDownloadURL -OutFile $FSInstallerZip -ErrorAction Stop
    Write-Output "FSLogix Download Complete."
}
Catch {
    Write-Output "FSLogix Download Failed: $_"
    Exit 1
}

# Extract FSLogix Installer
Try {
    Write-Output "Extracting FSLogix Installer..."
    Expand-Archive -LiteralPath $FSInstallerZip -DestinationPath $FSInstallerPath -Force
    Write-Output "FSLogix Extraction Complete."
}
Catch {
    Write-Output "FSLogix Extraction Failed: $_"
    Exit 1
}

# Install FSLogix
Try {
    Write-Output "Installing FSLogix..."
    $FSLogixExe = "$FSInstallerPath\x64\Release\FSLogixAppsSetup.exe"
    $FSLogixMsi = "$FSInstallerPath\FSLogixAppsSetup.msi"

    If (Test-Path $FSLogixExe) {
        Start-Process -FilePath $FSLogixExe -ArgumentList "/install /quiet" -Wait -ErrorAction Stop
    }
    ElseIf (Test-Path $FSLogixMsi) {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $FSLogixMsi /quiet /norestart" -Wait -ErrorAction Stop
    }
    Else {
        Write-Output "FSLogix Installer Not Found!"
        Exit 1
    }
    
    Write-Output "FSLogix Installation Completed Successfully."
}
Catch {
    Write-Output "FSLogix Installation Failed: $_"
    Exit 1
}

# Set FSLogix Profile Registry Keys
$ProfilePath = '\\aznonprodavdsa.file.core.windows.net\profiles'

Write-Output "Configuring FSLogix Profile Settings..."
If (!(Test-Path "HKLM:\Software\FSLogix\Profiles")) {
    New-Item -Path "HKLM:\Software\FSLogix" -Name "Profiles" -Force | Out-Null
}

$FSLogixSettings = @{
    "Enabled"                              = 1
    "VHDLocations"                         = $ProfilePath
    "SizeInMBs"                            = 15360
    "IsDynamic"                            = 1
    "ClearCacheOnLogoff"                   = 1
    "VolumeType"                           = "vhdx"
    "LockedRetryCount"                     = 12
    "DeleteLocalProfileWhenVHDShouldApply" = 1
    "LockedRetryInterval"                  = 5
    "ProfileType"                          = 3
    "ConcurrentUserSessions"               = 1
    "RoamSearch"                           = 2
    "FlipFlopProfileDirectoryName"         = 1
    "SIDDirNamePattern"                    = "%username%%sid%"
    "SIDDirNameMatch"                      = "%username%%sid%"
}

ForEach ($Key in $FSLogixSettings.Keys) {
    Set-ItemProperty -Path "HKLM:\Software\FSLogix\Profiles" -Name $Key -Value $FSLogixSettings[$Key] -Force
}

Write-Output "FSLogix Profile Configuration Completed."

# Configure FSLogix Office Profile Settings
Write-Output "Configuring FSLogix Office Profile..."
If (!(Test-Path "HKLM:\Software\Policies\FSLogix\ODFC")) {
    New-Item -Path "HKLM:\Software\Policies\FSLogix" -Name "ODFC" -Force | Out-Null
}

$OfficeProfileSettings = @{
    "Enabled"                    = 1
    "VHDLocations"               = $ProfilePath
    "VolumeType"                 = "vhdx"
    "FlipFlopProfileDirectoryName" = 1
    "DeleteLocalProfileWhenVHDShouldApply" = 1
    "SIDDirNamePattern"          = "%username%%sid%"
    "SIDDirNameMatch"            = "%username%%sid%"
    "RoamSearch"                 = 2
    "IncludeOneDrive"            = 1
    "IncludeOneNote"             = 1
    "IncludeOneNote_UWP"         = 0
    "IncludeOutlook"             = 1
    "IncludeOutlookPersonalization" = 1
    "IncludeSharepoint"          = 1
}

ForEach ($Key in $OfficeProfileSettings.Keys) {
    Set-ItemProperty -Path "HKLM:\Software\Policies\FSLogix\ODFC" -Name $Key -Value $OfficeProfileSettings[$Key] -Force
}

Write-Output "FSLogix Office Profile Configuration Completed."

# Restart to Apply Changes (Optional)
# Write-Output "Restarting Computer..."
# Restart-Computer -Force

# Script Completion Time
$EndTime = Get-Date
$ScriptRunTime = New-TimeSpan -Start $StartTime -End $EndTime
Write-Output "Total Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds"
Write-Output "FSLogix Setup Completed Successfully."
