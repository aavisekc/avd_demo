###################################################
#    Remove Bloatware from Windows in AVD VM Script   
#    Azure VM Generalization Script for Golden Image Creation
#    Written by Aavisek Choudhury
#    Microsoft MVP for AVD and Windows 365
###################################################

# Load parameters from JSON file
$paramFile = Get-Content '.\parameters.json' | ConvertFrom-Json
$rgName = $paramFile.ResourceGroupName  # Resource Group Name
$vmNames = $paramFile.VirtualMachineNames  # Array of Virtual Machine Names

# Capture the start time of the script execution
$StartTime = Get-Date

# Loop through each VM in the list
foreach ($vmName in $vmNames) {
    Write-Host "Processing VM: $vmName" -ForegroundColor Cyan
    
    # Get the source VM details, including its status
    $sourceVM = Get-AzVM -ResourceGroupName $rgName -Name $vmName -Status

    # Retrieve all status information of the VM
    $Status = $sourceVM.Statuses

    # Get the last recorded status of the VM
    $Count = $Status.Count
    $pos = $Count - 1 
    $NewStatus = $Status[$pos]
    $flag = $NewStatus.Code  # Extract the current power state

    # Check the VM status and deallocate if it's running or stopped
    if ($flag -eq "PowerState/running" -or $flag -eq "PowerState/stopped") {
        Write-Host "De-allocating the VM: $vmName..." -ForegroundColor Yellow
        Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Force
    } else {
        Write-Host "VM $vmName is already deallocated." -ForegroundColor Green
    }

    # Generalize the virtual machine
    Write-Host "Setting VM $vmName to Generalized state..." -ForegroundColor Yellow
    Set-AzVm -ResourceGroupName $rgName -Name $vmName -Generalized
    Write-Host "VM $vmName has been successfully generalized." -ForegroundColor Green
}

# Capture the end time of the script execution
$EndTime = Get-Date
$ScriptRunTime = New-TimeSpan -Start $StartTime -End $EndTime

# Display the total execution time
Write-Host "Total Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds" -ForegroundColor Cyan
