function New-SubscriptionRunTimeStatus {
    [CmdletBinding()]
    [OutputType(
        [PSCustomObject]
    )]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [Array]$StringArray
    )

    $StartLine = 1
    $EndLine = ($StringArray | Select-String -Pattern ':' -NotMatch | Select-Object -ExpandProperty LineNumber -First 1 -Skip 1) - 2
    
    $HashTable = [HashTable]::new()
    ($StringArray[$StartLine..$EndLine]).ForEach({
        $Parts = $_ -split ':'
        $HashTable.Add(
            $Parts[0].Trim(), $Parts[1].Trim()
        )
    })

    $Output = [PSCustomObject]$HashTable

    $Output.PSObject.TypeNames.Insert( 0, 'PSWecutil.SubscriptionRunTimeStatus')

    Write-Output -InputObject $Output
}
