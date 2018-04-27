<#
Code sniplet te re-use; detect ip subnet/network values from within a machine. Can be used for further deployment/configuration.
#>

    $Network =  Get-NetIPConfiguration | Where-Object {$_.IPv4Address.AddressState -eq 'Preferred'}
    $IPAddress = $Network.IPv4Address.IPAddress
    $PrefixLength = $Network.IPv4Address.PrefixLength
    $Gateway = $IPConfiguration.IPv4DefaultGateway
    $InterfaceAlias = $Network.IPv4Address.InterfaceAlias
    $DNS = $Network.DNSServer | Where-Object -Property AddressFamily -eq 'IPv4'
