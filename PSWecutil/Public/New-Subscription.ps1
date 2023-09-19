using module ..\PSWecutil.classes.psm1

function New-Subscription {
    [CmdletBinding()]
    [OutputType(
        [Subscription]
    )]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [Alias("SubscriptionName")]
        [String]$SubscriptionId,

        [Parameter(
            Mandatory = $true
        )]
        [ValidateSet("CollectorInitiated", "SourceInitiated")]
        [System.String]$SubscriptionType,

        [String]$Description,

        [Bool]$Enabled = $true,

        [ValidateSet("Push", "Pull")]
        [String]$DeliveryMode = "Push",

        [Int]$MaxItems = 1,

        [Int]$MaxLatencyTime = 20000,

        [Int]$HeartbeatInterval = 20000,

        [Bool]$ReadExistingEvents = $false,

        [ValidateSet("Http", "Https")]
        [String]$TransportName = "Http",

        [Int]$TransportPort = 5985,

        [String]$ContentFormat = "RenderedText",

        [String]$Locale = "en-US",

        [String]$LogFile = "ForwardedEvents",

        [ValidateSet("Default", "Basic", "Negotiate", "Digest")]
        [String]$CredentialsType = "Default"
    )

    [Xml]$xml = Get-Content -Path $PSScriptRoot\..\bin\Subscription.Template.xml

    $xml.Subscription.SubscriptionId = $SubscriptionId
    $xml.Subscription.SubscriptionType = $SubscriptionType
    $xml.Subscription.Description = $Description
    $xml.Subscription.Enabled = [String]$Enabled
    $xml.Subscription.Delivery.Mode = $DeliveryMode
    $xml.Subscription.Delivery.Batching.MaxItems = [String]$MaxItems
    $xml.Subscription.Delivery.Batching.MaxLatencyTime = [String]$MaxLatencyTime
    $xml.Subscription.Delivery.PushSettings.Heartbeat.Interval = [String]$HeartbeatInterval
    $xml.Subscription.ReadExistingEvents = [String]$ReadExistingEvents
    $xml.Subscription.TransportName = $TransportName
    $xml.Subscription.TransportPort = [String]$TransportPort
    $xml.Subscription.ContentFormat = $ContentFormat
    $xml.Subscription.Locale.Language = $Locale
    $xml.Subscription.LogFile = $LogFile

    if ($SubscriptionType -eq "CollectorInitiated") {
        $element = $xml.CreateElement(
            "CredentialsType", $xml.DocumentElement.NamespaceURI
        )
        
        [Void]$element.set_InnerText(
            $CredentialsType
        )

        $xml.Subscription.AppendChild(
            $element
        )
    }

    Format-Xml -Xml $xml.InnerXml
}
