function getUpdateDate {
    param(
        $machine,
        $credential,
        $server
    ) 

    $command = "Get-Date -Date (Get-HotFix | sort InstalledOn -desc)[0].InstalledOn -Format o"

    Write-Host "Checking machine: $($machine)"

    $date = Invoke-VMScript -VM $machine -GuestCredential $credential -ScriptType Powershell -ScriptText $command -Server $server

    if ($date) {
        return $date
    }
    else {
        Write-Host "No info on hotfixes, considering just installed or unavailable for scan"
        return Get-Date -Format o
    }

}

function CheckVmWareVCenter 
{
    param(
        [string]$ViServer,
        [string]$Vmhost,
        $Credential = (Get-Credential)
    )

    Get-Module -ListAvailable VMWare* | Import-Module

    Write-Host "Connecting to vSphere"
    $server = Connect-VIServer -Server $ViServer -Protocol https -Credential $Credential | Out-Null

    $patchDate = Get-Date -Date "2017-03-15T00:00:00.0000000" -F o 

    Write-Host "Getting Windows powered on machines"
    $allVms = Get-Vm | where { $_.PowerState -eq "PoweredOn" -and $_.ExtensionData.Guest.GuestFullName -like "*windows*" }

    $VmsUnderRisk = @()
    
    foreach ($vm in $allVms) {

        $updateDate = getUpdateDate -machine $vm -isVirtual $true -credential $Credential -server $server    
        $updateDate = Get-Date -Date $updateDate -Format o

        if ($updateDate -lt $currentDate)
        {
            Write-Host "Last update date is: $($updateDate)"
            Write-Host "$($VM) under risk!!! :O"
            $VmsUnderRisk += @($Vm.Name, $updateDate)
            write-host $VmsUnderRisk
        }
        else {
             Write-Host "$($VM) is ok!"
        }

    }

     $VmsUnderRisk | Out-file -FilePath "MACHINES_UNDER_RISK.txt"
    
}
