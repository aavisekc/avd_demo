# Define the log file location
$logFile = "C:\Temp\script_log.txt"

# Function to write to the log file
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

# Create the target directory if it does not exist
$targetDirectory = "C:\Temp"
if (-Not (Test-Path -Path $targetDirectory)) {
    New-Item -ItemType Directory -Path $targetDirectory
    Write-Log "Created directory: $targetDirectory"
} else {
    Write-Log "Directory already exists: $targetDirectory"
}

# Paths for the files to be downloaded
$vcRuntimeFile = "C:\temp\vc_redist.x64.exe"
$rdcwebrtcSvcFile = "C:\temp\MsRdcWebRTCSvc_HostSetup_1.50.2402.29001_x64.msi"
$teamsFile = "C:\temp\Teams_windows_x64.msi"

# Download C++ Runtime if it does not exist
if (-Not (Test-Path -Path $vcRuntimeFile)) {
    Write-Log "Starting download of C++ Runtime"
    invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile $vcRuntimeFile
    Write-Log "Downloaded C++ Runtime"
} else {
    Write-Log "C++ Runtime already exists at $vcRuntimeFile. Skipping download."
}
Start-Sleep -s 5

# Download RDCWEBRTCSvc if it does not exist
if (-Not (Test-Path -Path $rdcwebrtcSvcFile)) {
    Write-Log "Starting download of RDCWEBRTCSvc"
    invoke-WebRequest -Uri https://aka.ms/msrdcwebrtcsvc/msi -OutFile $rdcwebrtcSvcFile
    Write-Log "Downloaded RDCWEBRTCSvc"
} else {
    Write-Log "RDCWEBRTCSvc already exists at $rdcwebrtcSvcFile. Skipping download."
}
Start-Sleep -s 5

# Download Teams if it does not exist
if (-Not (Test-Path -Path $teamsFile)) {
    Write-Log "Starting download of Teams"
    invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2196106" -OutFile $teamsFile
    Write-Log "Downloaded Teams"
} else {
    Write-Log "Teams already exists at $teamsFile. Skipping download."
}
Start-Sleep -s 5

# Check for C++ Runtime installation by looking for its registry key
$vcRuntimeRegKey = "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
if (-Not (Test-Path -Path $vcRuntimeRegKey)) {
    Write-Log "Starting installation of C++ Runtime"
    Start-Process -FilePath $vcRuntimeFile -ArgumentList '/q', '/norestart' -Wait
    Write-Log "Installed C++ Runtime"
} else {
    Write-Log "C++ Runtime already installed. Skipping installation."
}
Start-Sleep -s 10

# Check for MSRDCWEBRTCSvc installation by looking for its registry key
$rdcwebrtcSvcRegKey = "HKLM:\SOFTWARE\Microsoft\MSRDCWEBRTCSvc"
if (-Not (Test-Path -Path $rdcwebrtcSvcRegKey)) {
    Write-Log "Starting installation of MSRDCWEBRTCSvc"
    Start-Process -FilePath msiexec -ArgumentList "/i $rdcwebrtcSvcFile /q /n" -Wait
    Write-Log "Installed MSRDCWEBRTCSvc"
} else {
    Write-Log "MSRDCWEBRTCSvc already installed. Skipping installation."
}
Start-Sleep -s 10

# Define the URLs and target file paths for additional downloads
$urls = @{
    "https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409" = "$targetDirectory\teamsbootstrapper.exe"
    "https://go.microsoft.com/fwlink/?linkid=2196106" = "$targetDirectory\TeamsSetup.msix"
}

# Download each file if it does not already exist
foreach ($url in $urls.Keys) {
    $targetPath = $urls[$url]
    if (-Not (Test-Path -Path $targetPath)) {
        Write-Log "Downloading $url to $targetPath"
        Invoke-WebRequest -Uri $url -OutFile $targetPath
        Write-Log "Downloaded $url to $targetPath"
    } else {
        Write-Log "File $targetPath already exists. Skipping download."
    }
}

# Run the teamsbootstrapper.exe with parameters if it exists
$teamsBootstrapperPath = $urls["https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409"]
if (Test-Path -Path $teamsBootstrapperPath) {
    Write-Log "Running teamsbootstrapper.exe with parameters."
    Start-Process -FilePath $teamsBootstrapperPath -ArgumentList "-p -o `"c:\Temp\TeamsSetup.msix`"" -Wait
    Write-Log "Ran teamsbootstrapper.exe successfully."
} else {
    Write-Log "Teams bootstrapper not found at $teamsBootstrapperPath. Aborting installation."
    exit 1
}

Write-Log "Script execution complete."

# Set registry key indicating the environment
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Name IsWVDEnvironment -PropertyType DWORD -Value 1 -Force | Out-Null
Write-Log "Set IsWVDEnvironment registry key to 1"
