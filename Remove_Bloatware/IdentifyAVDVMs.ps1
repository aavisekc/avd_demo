###################################################
#    Remove Bloatware from Windows in AVD VM Script   #
#    Written by Aavisek Choudhury
#    Microsoft MVP for AVD and Windows 365
###################################################


# Import Variables values from csv file
$variables = import-csv '.\Path1\Path2\AVDInfra.csv' -delimiter ","

foreach ($variable in $variables)
{
    # Assign values from CSV to variables
    $ResourceGroupName=$variable.HostPoolrgName
    $azHostPoolName = $variable.AVDHostPoolName
    $azhostpoolRg = $variable.HostPoolrgName
}

# Assign values to ResourceGroupName and HostPoolName
$ResourceGroupName = $azhostpoolRg
$HostPoolName =  $azHostPoolName

# Fetch the AVD Host Pool Information
$WVDHostPool=Get-AzWvdHostPool | Where-Object {$_.Name -eq $HostPoolName}
Write-Host "Trying to Fetch the AVD Host Pool Information....." -ForegroundColor "Green"

$HostPoolList=@()
$pool=$WVDHostPool.Name

# Loop through each pool and get details
foreach($item in $Pool)
{
    $HostPoolObject = New-Object PSObject
    $HospoolDetails=Get-AzResource -Name $item | Where-Object {$_.ResourceType -eq "Microsoft.DesktopVirtualization/hostpools"}
    $poolName=$HospoolDetails.Name
    $poolRG=$HospoolDetails.ResourceGroupName

    # Add details to HostPoolObject
    $HostPoolObject | Add-Member -MemberType NoteProperty -Name "PoolName" -Value $poolName 
    $HostPoolObject | Add-Member -MemberType NoteProperty -Name "PoolResourceGroup" -Value $poolRG
    $HostPoolList += $HostPoolObject
} 

$SessionHostList=@()

# Loop through each HostPool and get session host details
foreach($item in $HostPoolList)
{
    $SessionHostObject = New-Object PSObject
    $SessionHostDetails=Get-AzWvdSessionHost -ResourceGroupName $Item.PoolResourceGroup -HostPoolName $Item.PoolName
    $SessionHostPoolRG=$Item.PoolResourceGroup
    $SessionHostPoolName=$Item.PoolName
    $sessionHostName=$SessionHostDetails.Name

    # Add details to SessionHostObject
    $SessionHostObject | Add-Member -MemberType NoteProperty -Name "SessionHostResourceGroup" -Value $SessionHostPoolRG
    $SessionHostObject | Add-Member -MemberType NoteProperty -Name "SessionHostPool" -Value $SessionHostPoolName
    $SessionHostObject | Add-Member -MemberType NoteProperty -Name "SessionHostName" -Value $sessionHostName
    $SessionHostList += $SessionHostObject
} 

Write-Host "Able to fetch the session host information about the AVD Host Pool........" -ForegroundColor "Green"
$SessionHostList | Format-Table -AutoSize

[object[]]$desiredOutput = @()

# Process session host list to get desired output
$desiredOutput+= @($SessionHostList).ForEach({
    New-Variable -Name currentItem -Value $PSItem -Force
    @($currentItem.SessionHostName).Foreach({
        $sessionHostName = $_
        [object]$objExcludingSessionHostName = $currentItem | Select-Object -Property * -ExcludeProperty SessionHostName
        $objExcludingSessionHostName | Add-Member -MemberType NoteProperty -Name SessionHostName -Value $sessionHostName
        Write-Output -InputObject $objExcludingSessionHostName
    })
})

$VMList=$desiredOutput | Select-Object -Property SessionHostName

Write-Host "Trying to align each AVD Session Hosts with the AVD Host Pool" -ForegroundColor "Green"
$VMList

$VM=$desiredOutput
$fqdnList=@()

# Extract FQDN of the session host
foreach ($item1 in $VM)
{
    $fqdnobj = New-Object PSObject
    $vmfqdn1=$item1.SessionHostName
    $vmfqdn=($vmfqdn1 -split '/')[1]
    $vmhostpool=$item1.SessionHostPool

    # Add details to fqdnobj
    $fqdnobj | Add-Member -MemberType NoteProperty -Name "VMName" -Value $vmfqdn
    $fqdnobj | Add-Member -MemberType NoteProperty -Name "HostPoolName" -Value $vmhostpool
    $fqdnList += $fqdnobj
}

Write-Host "Able to extract FQDN of the session host from the WVD Session Host info stored in Azure.........." -ForegroundColor "Green"
$fqdnList | Format-Table -AutoSize

$fqdn=$fqdnList | Where-Object {$_.VMName -ne $null}

Write-Host "Filtering the AVD Host Pool which have atleast one Session Host.........." -ForegroundColor "Green"
$fqdn | Format-Table -AutoSize

$finalvmname=@()

# Find azure VM information associated with WVD HostPool
foreach ($item2 in $fqdn)
{
    $finalvmobj=New-Object PSObject
    $a=$item2.HostPoolName
    $b=$item2.VMName
    $pos=$b.IndexOf(".")
    $leftPart = $b.Substring(0, $pos)

    # Add details to finalvmobj
    $finalvmobj | Add-Member -MemberType NoteProperty -Name "Name" -Value $leftPart
    $finalvmobj | Add-Member -MemberType NoteProperty -Name "HostPoolName" -Value $a
    $finalvmname+=$finalvmobj 
}

Write-Host "Able to find azure VM information associated with WVD HostPool............" -ForegroundColor "Green"
$finalvmname | Format-Table -AutoSize

$desiredvmlist=($finalvmname | Where-Object -Property "HostPoolName" -eq $HostPoolName) | Select-Object -Property "Name"

Write-Host "Able to find the Session Host associated with $HostPoolName............" -ForegroundColor "Yellow"
$temp=$desiredvmlist.Name
$vmcount = $temp.length

# Run Bloatware Script on each VM if it is running
if ($vmcount -gt 0)
{
    Foreach ($item in $temp)
    {
        $sourceVM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $item -Status
        $vm=$sourceVM.Name

        # Find all the Status of the VM
        $Status = $sourceVM.Statuses

        # Find the Last Status of the VM
        $Count=$Status.Count
        $pos = $Count-1 
        $NewStatus=$Status[$pos]
        $flag=$NewStatus.Code

        if($flag -eq "PowerState/running")
        {
            Write-Host "Running the Bloatware Script in resource group $ResourceGroupName and in VM $item"
            Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -Name $item  -CommandId 'RunPowerShellScript' -ScriptPath '.\_AVDInfra-CI\AVDInfraArtifact\RemoveBloatware.ps1'
            Write-Host "Bloatware Completed on $item, Congratulations!!!"
        }
        else
        {
            Write-Host "VM $item is already deallocated, so Bloatware Script will not work"
        }
    }   
}