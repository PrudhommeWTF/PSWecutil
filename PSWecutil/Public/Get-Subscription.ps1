using module ..\PSWecutil.classes.psm1

function Get-Subscription {
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String[]]$SubscriptionId = $null,

        [Switch]$AsXml,

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
            if ($AsXml.IsPresent) {
                $Output = Format-Xml -Xml $subscription.InnerXml
            } else {
                $Output = [Subscription]$subscription

                $Output.PSObject.TypeNames.Insert(0, 'PSWecutil.Subscription')
            }

            Add-Member -InputObject $Output -NotePropertyName PSComputerName -NotePropertyValue $ComputerName
            
            Write-Output -InputObject $Output
        }
    }

    if ($Session) {
        Remove-PSSession -Session $Session
    }
}