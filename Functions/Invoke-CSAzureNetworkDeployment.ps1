#Requires –Modules GenericFunctions,AzureRM.Profile

function Invoke-CSAzureNetworkDeployment{
    <#
    .Synopsis
    Creates IP information for each defined subnet for CloudSuite network templates

    .Description

    #>
    [CmdLetBinding()]
    Param(
        #The network base address or network id for the total network range of this deployment/solution
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Net.IPAddress]$NetworkAddress,
        #The type of network to deploy, based on the provided NetworkAddress and the
        [ValidateSet('Small','Medium','Large')]
        [string]$Type = 'Small', #'Medium
        #Optional. Provide which subnets to exclude from prosessing. Will result in lesser networks being created.
        #Used name must comply with CloudSuite network template naming. Default is minimum install.
        [ValidateSet('Lan','Dmz','Mgt','Fw','Gw')]
        [string[]]$Exclude = @('Fw','Gw'),
        #Path to the json file which contains current default subnet templates CloudSuite network 
        [string]$SubnetTemplatePath = '\Settings\CSSubnetTemplate.json',
        #Path to the json file which contains valid networks to deploy the CloudSuite network to. Currently only contains networks as stated by RFC1918  Used for checking the provdied NetworkAddress
        [string]$ValidNetworksPath = '\Settings\ValidNetworks.json'        
    )

    Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss:fff'): $($MyInvocation.MyCommand.Name): Starting"

    foreach ($PSBoundParameter in $PSBoundParameters.GetEnumerator()) {
        Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss:fff'): [Parameter]: $($PSBoundParameter.Key) : [Value]: $($PSBoundParameter.Value)"
    }

    #Check for AzureRMSession, based on 
    #https://stackoverflow.com/questions/28105095/how-to-detect-if-azure-powershell-session-has-expired
    Try{
        $content = Get-AzureRmContext -ErrorAction Stop
        if ([string]::IsNullOrEmpty($content.Account)){
            Write-Error -Message "No session to Azure detected. Use Login-AzureRmAccount to login first"
            break
        } 
    } 
    Catch 
    {
        Write-Error -Message "$($_)"
        break
    }

    #Check pre-req's to be able to run this function
    $PSModuleName = (Get-Command -Name $($MyInvocation.MyCommand.Name)).Source
    [xml]$ModuleTAG = (Get-Package $PSModuleName ).SwidTagText
    $PSModulePath = $ModuleTAG.SoftwareIdentity.Meta.InstalledLocation
    $SubnetTemplate = Get-JsonFile -Path "$($PSModulePath)$($SubnetTemplatePath)"
    $ValidNetworks = Get-JsonFile -Path "$($PSModulePath)$($ValidNetworksPath)"


    <#
    $Network =  Get-NetIPConfiguration | Where-Object {$_.IPv4Address.AddressState -eq 'Preferred'}
    $IPAddress = $Network.IPv4Address.IPAddress
    $PrefixLength = $Network.IPv4Address.PrefixLength
    $Gateway = $IPConfiguration.IPv4DefaultGateway
    $InterfaceAlias = $Network.IPv4Address.InterfaceAlias
    $DNS = $Network.DNSServer | Where-Object -Property AddressFamily -eq 'IPv4'
    #>

    #Determine subnets for given VNet and Size
    $PN = $PrivateNetworks | Where-Object {$_.ID.Split('.')[0] -eq $VnetOctet[0]}
    If (!($PN)){
        Write-Error -Message "Provided NetworkID is not an allowed IPv4 Private Network as stated by RFC1918. Interference in communication may occur. Please provide other networkID."
        break
    }
    else{
        If ($Mask -lt $PN.Mask){
            Write-Error -Message "Provided mask creates a network range outside the boundaries as stated by RFC1918. Interference in communication may occur. Please provide a different mask"
            break
        }
    }
    If (($Mask + 6) -gt 29){
        Write-Error -Message "Provided mask is too small to create networks with minimum host ranges. Please provide a different mask"
        break  
    }

    #Get the subnets for deployment

    $CSNetworkTemplate = $SubnetTemplate | Where-Object -Property Type -eq $Type
    
    $Subnets = @()
    $NewNetworkID = $Network
    $Mask = $CSNetworkTemplate.MaskMin
    $OldNetworkMask = $CSNetworkTemplate.MaskMin

    $GroupedSubnets = $CSNetworkTemplate.Subnet | Group-Object Maskdiv

    Foreach ($GroupedSubnet in $GroupedSubnets){
        $NetSubnetMask = $Mask + ($GroupedSubnet.Name)
        $NetSubnets = Get-IPSubnet -NetworkID $NewNetworkID -Mask $OldNetworkMask -SubnetMask $NetSubnetMask
        $i = 1
        Foreach ($Subnet in $GroupedSubnet.Group){
            $Info = @{
                SubnetName = "$($Subnet.Name)SubnetCIDR"
                CIDR = "$($NewNetworkID)/$($NetSubnetMask)"
            }
            $Subnets += [PSCustomObject]$Info
            $NewNetworkID = $NetSubnets[$i]
            $i++
        }
        $NewNetworkID
        $OldNetworkMask = $NetSubnetMask
    }
    <#
    $LANSubnetMask = $Mask + $SubnetTemplate.Prefix.Lan
    $LANSubnetCIDR = "$($Network)/$($LANSubnetMask)"
    $NewNetworkID = Get-IPSubnet -NetworkID $Network -Mask $Mask -SubnetMask ($LANSubnetMask)

    $DMZSubnetNetworkID = $NewNetworkID[1]
    $DMZSubnetMask = $Mask + $SubnetTemplate.Prefix.Dmz
    $DMZSubnetCIDR = "$($DMZSubnetNetworkID)/$($DMZSubnetMask)"
    $NewNetworkID = Get-IPSubnet -NetworkID $DMZSubnetNetworkID -Mask $Mask -SubnetMask ($Mask + $SubnetTemplate.Prefix.Lan)

    $LANSubnetMask = 
        
    #Get the range of current network
    $StartAddress = [IPAddress]$VnetID
    $CurrentMask = $Mask
    $EndAddress = Get-IPAddressFromSubnet -SubnetAddress $StartAddress -PrefixLength $CurrentMask -NodeAddress -1
    $IPRange = New-Range $StartAddress $EndAddress
    #Split provided network in halve; largest portion for LAN
    $CurrentMask++
    $LANSubnetCIDR = "$($StartAddress)/$($CurrentMask)"    
    $SubnetEndAddress = Get-IPAddressFromSubnet -SubnetAddress $StartAddress -PrefixLength $CurrentMask -NodeAddress -1
    #https://stackoverflow.com/questions/1785474/get-index-of-current-item-in-powershell-loop
    $NewSubnetStartAddress = $IPRange[([array]::IndexOf($IPRange, $SubnetEndAddress)) + 1]








    #Use the remaining range for other networks


    $DMZSubnetMask = 
    $LANSubnetMask = 


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