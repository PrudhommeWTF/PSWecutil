function New-SubscriptionRunTimeStatusEventSource {

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

    $StartLine = ($StringArray | Select-String ':' -NotMatch | Select-Object -ExpandProperty LineNumber -First 1 -Skip 1) - 1
    $EndLine = ($StringArray | Select-String ':' -NotMatch | Select-Object -ExpandProperty LineNumber -First 1 -Skip 2) - 2
    if ($EndLine -lt 0) {
        $EndLine = $StringArray.Count
    }
    $Range = $EndLine - $StartLine

    $Output = @()
    for ($i = $StartLine; $i -lt $StringArray.Count; $i += $Range + 1) {
        $HashTable = [HashTable]::new()
        ($StringArray[$i..($i + $Range)]).ForEach({
            $Parts = $_ -split ':'
            if ($Parts.Count -eq 1) {
                $HashTable.Add('EventSource', $Parts[0].Trim())
            } else {
                $HashTable.Add(
                    $Parts[0].Trim(), ($Parts[1..$Parts.count] -join ':').Trim()
                )
            }
        })

        $Output += [PSCustomObject]$HashTable

        $Output.PSObject.TypeNames.Insert(0, 'PSWecutil.SubscriptionRunTimeStatusEventSource')
    }
    Write-Output -InputObject $Output
}
