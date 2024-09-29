# Script Created by Aavisek Choudhury
# Check if HDX Teams Redirection is enabled by looking at the registry
$hdxKeyPath = "HKLM:\SOFTWARE\Citrix\HDXMediaStream"
$hdxOptimization = Get-ItemProperty -Path $hdxKeyPath -Name "Teams"

if ($hdxOptimization.Teams -eq 1) {
    Write-Output "HDX Optimization for Teams is enabled."
} else {
    Write-Output "HDX Optimization for Teams is NOT enabled."
}

# Check if HDX Teams process is running
$process = Get-Process -Name "Teams" -ErrorAction SilentlyContinue
if ($process) {
    Write-Output "Teams is running."
} else {
    Write-Output "Teams is NOT running."
}

# Check if HDX Media Engine is active
$mediaEngineProcess = Get-Process -Name "HdxRtcEngine" -ErrorAction SilentlyContinue
if ($mediaEngineProcess) {
    Write-Output "HDX Media Engine is running (Optimization Loaded)."
} else {
    Write-Output "HDX Media Engine is NOT running (Optimization not loaded)."
}
