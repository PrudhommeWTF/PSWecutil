using module ..\PSWecutil.classes.psm1

function Import-Subscription {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    [OutputType()]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [ValidateScript({
            Test-Path -Path $_
        })]
        [String]$XmlPath,

        [String]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential = [PSCredential]::Empty
    )

    $ScriptBlock = [ScriptBlock]{
        Param(
            $SubscriptionId,
            $XmlFileContent
        )
        if ((Get-Service -Name Wecsvc).Status -eq "Running") {
            $FilePath = "$env:tmp\$SubscriptionId.xml"
            $XmlFileContent | Out-File -FilePath $FilePath
            [Xml]$output = wecutil.exe create-subscription "$FilePath" /format:XML

            Write-Output -InputObject $output
        } else {
            throw "Service not running."
        }
    }

    $XmlFileContent = Get-Content -Path $XmlPath
    $SubscriptionId = Split-Path -Path $XmlPath -Leaf

    $InvokeCommand101 = [Collections.Hashtable]@{
        ScriptBlock = $ScriptBlock
        ArgumentList = $SubscriptionId, $XmlFileContent
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
    $ShouldProcess = $PSCmdlet.ShouldProcess(
        $SubscriptionId
    )
    if ($ShouldProcess) {
        Invoke-Command @InvokeCommand101
    }

    if ($Session) {
        Remove-PSSession -Session $Session
    }
}