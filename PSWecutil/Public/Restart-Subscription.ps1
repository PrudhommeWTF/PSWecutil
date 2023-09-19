function Restart-Subscription {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    [OutputType()]

    Param(
        [Parameter(
            Mandatory = $true
        )]
        [String[]]$SubscriptionId,

        [String]$EventSource,

        [String]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential
    )

    $ScriptBlock = [ScriptBlock]{
        if ((Get-Service -Name Wecsvc).Status -eq 'Running' ) {
            $Subscriptions = wecutil.exe enum-subscription

            foreach ($arg in $args[0]) {
                if ($arg -in $Subscriptions) {
                    wecutil.exe retry-subscription "$arg" "$($args[1])"
                } else {
                    Write-Error "Subscription not found: '$arg'."
                    continue
                }
            }
        } else {
            throw 'Service not running.'
        }
    }

    $ShouldProcess = $PSCmdlet.ShouldProcess(
        $SubscriptionId
    )
    if ($ShouldProcess) {
        $InvokeCommand101 = [Collections.Hashtable]@{
            ScriptBlock = $ScriptBlock
            ArgumentList = $SubscriptionId, $EventSource
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