function Format-Xml {
    [CmdletBinding()]
    [OutputType()]
    Param(
        [Xml]$Xml
    )

    $StringWriter = New-Object -TypeName 'System.IO.StringWriter'
    $XmlTextWriter = New-Object -TypeName 'System.Xml.XmlTextWriter' $StringWriter -Property @{
        Formatting = 'Indented'
    }

    $Xml.WriteTo(
        $XmlTextWriter
    )

    $XmlTextWriter.Flush()
    $StringWriter.Flush()

    Write-Output $StringWriter.ToString();
}
