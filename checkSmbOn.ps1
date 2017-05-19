function executePsRemoteCommand($command, $machine, $credenital, $elevated)
{
    $script = {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo -ArgumentList 'C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe'
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $commandEncoded = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Using:command))
        $pinfo.Arguments = '-NoProfile -NonInteractive -EncodedCommand {0}' -f $commandEncoded
        $pinfo.WindowStyle = 'Hidden'
        if ($elevated) {
            $pinfo.Verb = "runas"
        }
        $pinfo.UseShellExecute = $false
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()
        New-Object -TypeName Hashtable @{"output"=$stdout+$stderr;"stderr"=$stderr;"exit_code"=[string]$p.ExitCode}
    }

    $remotePsSession = New-PSSession -ComputerName $machine -Credential $credential -EnableNetworkAccess
    $output = Invoke-Command -Session $remotePsSession -ScriptBlock $script
    Remove-PSSession -Session $remotePsSession

    return $output
}

function checkSmbOn($machine, $credential) {

    $command = '$(Get-SmbServerConfiguration | Select EnableSMB1Protocol).EnableSMB1Protocol'
    $output = executePsRemoteCommand -command $command -machine $machine -credential $credential -elevated $false
    if ($output.output -match "True") {return $true}
    elseif ($output.output -match "False") {return $false}
    else {return "undefined"}

}

