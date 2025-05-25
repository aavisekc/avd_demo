$CLSIDs = @()
foreach($registryKey in (Get-ChildItem "Registry::HKEY_CLASSES_ROOT\CLSID" -Recurse)){
    If (($registryKey.GetValueNames() | %{$registryKey.GetValue($_)}) -eq "Drive or folder redirected using Remote Desktop") {
        $CLSIDs += $registryKey
    }
}

$drives = @()
foreach ($CLSID in $CLSIDs.PSPath) {
    $drives += (Get-ItemProperty $CLSID)."(default)"
}

Write-Output "These are the local drives redirected to the remote session:`n"
$drives