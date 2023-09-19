function Invoke-WindowsEventCollectorQuickConfiguration {
    [CmdletBinding(
        ConfirmImpact = "High",
        SupportsShouldProcess = $true
    )]
    [OutputType(
        [Void]
    )]
    Param(
        [Switch]$Confirm,

        [String]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential = [PSCredential]::Empty
    )
    $ScriptBlock = [ScriptBlock]{
        wecutil.exe quick-config /q:true
    }

    $ShouldProcess = $PSCmdlet.ShouldProcess(
        $ComputerName
    )
    if ($ShouldProcess) {
        $InvokeCommand101 = [Collections.Hashtable]@{
            ScriptBlock = $ScriptBlock
            ArgumentList = $SubscriptionId
        }
        if (!($ComputerName -eq $env:COMPUTERNAME)) {
            try {
                if (Get-PSSession | Where-Object -FilterScript {$_.ComputerName -eq $ComputerName -and $_.State -ne 'Broken'}) {
                    $Session = Get-PSSession -ComputerName $ComputerName -ErrorAction Stop
                } else {
                    $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
                }
            }
            catch {throw $_}
        
            $InvokeCommand101.Add('Session', $Session)
        }
        Invoke-Command @InvokeCommand101
    }

    if ($Session) {
        Remove-PSSession -Session $Session
    }
}