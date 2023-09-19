function Remove-Subscription {

    [CmdletBinding(
        ConfirmImpact = 'High',
        SupportsShouldProcess = $true
    )]
    [OutputType(
        [Void]
    )]

    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String[]]$SubscriptionId,

        [String]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential = [PSCredential]::Empty
    )

    $ScriptBlock = [ScriptBlock]{
        if ((Get-Service -Name Wecsvc).Status -eq 'Running' ) {
            $Subscriptions = wecutil.exe enum-subscription

            foreach ($arg in $args) {
                if ($arg -in $Subscriptions) {
                    wecutil.exe delete-subscription "$arg"
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