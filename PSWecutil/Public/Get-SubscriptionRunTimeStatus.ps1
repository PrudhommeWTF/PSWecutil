function Get-SubscriptionRunTimeStatus {
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String[]]$SubscriptionId,

        [String]$EventSource,

        [String]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential = [PSCredential]::Empty
    )

    $ScriptBlock = [ScriptBlock]{
        if ((Get-Service -Name Wecsvc).Status -eq 'Running') {
            $Subscriptions = wecutil.exe enum-subscription

            foreach ($arg in $args[0]) {
                if ($arg -in $Subscriptions) {
                    $Output = wecutil.exe get-subscriptionruntimestatus "$arg" "$($args[1])"
    
                    Write-Output -InputObject $Output
                } else {
                    Write-Error "Subscription not found: '$arg'."
                    continue
                }
            }  
        } else {
            throw 'Service not running.'
        }

    }

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
    $SubscriptionRunTimeStatus = Invoke-Command @InvokeCommand101

    $Output = New-SubscriptionRuntimeStatus -StringArray $SubscriptionRunTimeStatus
    $EventSourceOutput = New-SubscriptionRuntimeStatusEventSource -StringArray $SubscriptionRunTimeStatus
    $OutputProperties = $output | Get-Member | Select-Object -ExpandProperty Name
    if ('EventSources' -notin $outputProperties) {
        Add-Member -InputObject $Output -NotePropertyName 'EventSources' -NotePropertyValue $eventSourceOutput 
    } else {
        $Output.EventSources = $EventSourceOutput
    }

    Add-Member -InputObject $Output -NotePropertyName PSComputerName -NotePropertyValue $ComputerName

    Write-Output -InputObject $output

    if ($Session) {
        Remove-PSSession -Session $Session
    }
}