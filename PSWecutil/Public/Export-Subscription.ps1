using module ..\PSWecutil.classes.psm1

function Export-Subscription {
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String[]]$SubscriptionId = $null,

        [String]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential = [PSCredential]::Empty
    )

    $ScriptBlock = [ScriptBlock]{
        if ((Get-Service -Name Wecsvc).Status -eq 'Running') {
            $Subscriptions = wecutil.exe enum-subscription

            if ($args.Count -eq 0) {
                foreach ($subscription in $Subscriptions) {
                    [Xml]$output = wecutil.exe get-subscription "$subscription" /format:XML
    
                    Write-Output -InputObject $output
                }
            } else {
                foreach ($arg in $args) {
                    if ($arg -in $Subscriptions) {
                        [Xml]$output = wecutil.exe get-subscription $arg /format:XML
    
                        Write-Output -InputObject $output
                    } else {
                        Write-Error "Subscription not found: '$arg'."
                        continue
                    }
                }
            }    
        } else {
            throw 'Service not running.'
        }
    }

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
    $Subscriptions = Invoke-Command @InvokeCommand101

    foreach ($subscription in $Subscriptions) {
        if ($null -ne $subscription) {
            $Output = Format-Xml -Xml $subscription.InnerXml
            try {
                Out-File -InputObject $Output -FilePath ('{0}\{1}.xml' -f $env:TMP, $($subscription.Subscription.SubscriptionId -replace ' ','_'))
                Write-Host -ForegroundColor Green -Object ('XML File Exported: {0}\{1}.xml' -f $env:TMP, $($subscription.Subscription.SubscriptionId -replace ' ','_'))
            }
            catch {
                $_ | Write-Error
            }
        }
    }

    if ($Session) {
        Remove-PSSession -Session $Session
    }
}
