# Script Created by Aavisek Choudhury
# Check if local drives are redirected in a remote session by looking at the registry
# This script checks for local drive redirection in a remote session by examining the Windows registry.

try {
    $CLSIDs = @()
    $baseKey = "Registry::HKEY_CLASSES_ROOT\CLSID"

    # Get all subkeys under the CLSID registry key
    $subKeys = Get-ChildItem -Path $baseKey -ErrorAction Stop

    foreach ($registryKey in $subKeys) {
        try {
            # Read all value names and their associated data
            foreach ($valueName in $registryKey.GetValueNames()) {
                $valueData = $registryKey.GetValue($valueName)
                if ($valueData -eq "Drive or folder redirected using Remote Desktop") {
                    $CLSIDs += $registryKey.PSPath
                    break
                }
            }
        }
        catch {
            Write-Warning "Failed to read values from key: $($registryKey.PSChildName). Error: $_"
        }
    }

    if ($CLSIDs.Count -eq 0) {
        Write-Output "No redirected drives found in the registry."
    } else {
        $drives = @()
        foreach ($CLSIDPath in $CLSIDs) {
            try {
                $defaultValue = (Get-ItemProperty -Path $CLSIDPath -ErrorAction Stop)."(default)"
                $drives += $defaultValue
            }
            catch {
                Write-Warning "Could not retrieve default value for key: $CLSIDPath. Error: $_"
            }
        }

        if ($drives.Count -gt 0) {
            Write-Output "These are the local drives redirected to the remote session:`n"
            $drives | ForEach-Object { Write-Output $_ }
        }
        else {
            Write-Output "Redirected CLSID keys found but no valid drive names were retrieved."
        }
    }
}
catch {
    Write-Error "An unexpected error occurred: $_"
}
