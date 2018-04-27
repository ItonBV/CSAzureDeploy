#Requires -Modules GenericFunctions

function Get-CSAzureSubnets{
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [IPAddress]$Network = '172.17.0.0',
        [parameter(Position = 1)]
        [ValidateRange(0,32)]
        [int]$PrefixLength,
        [Parameter(Position = 2)]
        [ValidateSet('Small','Medium','Large')]
        [String]$Type = 'Medium',
        
        [String]$Path = '..\Config\CSSubnetTemplate.json'
    )

    $splatParam = @{}
    If ($PrefixLength){$splatParam.PrefixLength = $PrefixLength}
    If (!(Test-IPInPrivateNetwork -IPAddress $Network @splatParam)){
        Write-Error -Message "Provided Network is not an allowed IPv4 Private Network as stated by RFC1918. Interference in communication may occur. Please provide other networkID."
        break
    }

    $SCSubnetTemplate = Get-JsonFile -Path $Path
    $CSCurrentTemplate = $SCSubnetTemplate | Where-Object -Property Type -eq $Type

    If ($PrefixLength){
        If ($PrefixLength -gt $CSCurrentTemplate.PrefixMin){
            Write-Error -Message "Provided network parameters are to small for chosen network deployment type `'$($Type)`'."
            break
        }
        $Prefix = $PrefixLength
    }
    else{
        $Prefix = $CSCurrentTemplate.PrefixMin
    }
    
    $Subnets = @()
    $NewNetworkID = $Network
    $OldNetworkPrefix = $Prefix
    $GroupedSubnets = $CSCurrentTemplate.Subnet | Group-Object Prefixdiv
    Foreach ($GroupedSubnet in $GroupedSubnets){
        $NetSubnetPrefix = $Prefix + ($GroupedSubnet.Name)
        $NetSubnets = Get-IPSubnet -SubnetAddress $NewNetworkID -PrefixLength $OldNetworkPrefix -SubnetPrefix $NetSubnetPrefix
        $i = 1
        Foreach ($Subnet in $GroupedSubnet.Group){
            $Info = @{
                Name = [String]$Subnet.Name
                NetworkAddress = [IPAddress]$NewNetworkID
                Mask = ConvertFrom-IPPrefix -PrefixLength $NetSubnetPrefix
                PrefixLength = [int]$NetSubnetPrefix
                CIDR = "$($NewNetworkID)/$($NetSubnetPrefix)"
            }
            $Subnets += [PSCustomObject]$Info
            $NewNetworkID = $NetSubnets[$i]
            $i++
        }
        $OldNetworkPrefix = $NetSubnetPrefix
    }
    return $Subnets
}

function Get-Test{
       <#
    $LANSubnetPrefix = $Prefix + $SubnetTemplate.Prefix.Lan
    $LANSubnetCIDR = "$($Network)/$($LANSubnetPrefix)"
    $NewNetworkID = Get-IPSubnet -NetworkID $Network -Prefix $Prefix -SubnetPrefix ($LANSubnetPrefix)

    $DMZSubnetNetworkID = $NewNetworkID[1]
    $DMZSubnetPrefix = $Prefix + $SubnetTemplate.Prefix.Dmz
    $DMZSubnetCIDR = "$($DMZSubnetNetworkID)/$($DMZSubnetPrefix)"
    $NewNetworkID = Get-IPSubnet -NetworkID $DMZSubnetNetworkID -Prefix $Prefix -SubnetPrefix ($Prefix + $SubnetTemplate.Prefix.Lan)

    $LANSubnetPrefix = 
        
    #Get the range of current network
    $StartAddress = [IPAddress]$VnetID
    $CurrentPrefix = $Prefix
    $EndAddress = Get-IPAddressFromSubnet -SubnetAddress $StartAddress -PrefixLength $CurrentPrefix -NodeAddress -1
    $IPRange = New-Range $StartAddress $EndAddress
    #Split provided network in halve; largest portion for LAN
    $CurrentPrefix++
    $LANSubnetCIDR = "$($StartAddress)/$($CurrentPrefix)"    
    $SubnetEndAddress = Get-IPAddressFromSubnet -SubnetAddress $StartAddress -PrefixLength $CurrentPrefix -NodeAddress -1
    #https://stackoverflow.com/questions/1785474/get-index-of-current-item-in-powershell-loop
    $NewSubnetStartAddress = $IPRange[([array]::IndexOf($IPRange, $SubnetEndAddress)) + 1]








    #Use the remaining range for other networks


    $DMZSubnetPrefix = 
    $LANSubnetPrefix = 


    $SubnetID = Get-IPAddressFromSubnet -SubnetAddress $IPAddress -PrefixLength $PrefixLength -NodeAddress 0
    $StartAddress = Get-IPAddressFromSubnet -SubnetAddress $IPAddress -PrefixLength $PrefixLength -NodeAddress 1
    $EndAddress = Get-IPAddressFromSubnet -SubnetAddress $IPAddress -PrefixLength $PrefixLength -NodeAddress -1

    Ping-IPRange -StartAddress $StartAddress -EndAddress $EndAddress

    Ping-PSRemote -StartAddress $StartAddress -EndAddress $EndAddress

    <#
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
            [ValidateScript({$_ -match [IPAddress]$_ })]  
            [string]
            $IPAddress

    #>
}
