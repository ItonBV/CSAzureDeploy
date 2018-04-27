#Requires -Modules GenericFunctions

function Get-CDNodeIPs{
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSObject]$Subnet,
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [String]$Path = '..\Config\CsCdHosts.json'
    )

    Begin{
        #Force a collection for valid 'where' clauses
        $ScCdHostsTemplate = @()
        $ScCdHostsTemplate += Get-JsonFile -Path $Path
    }
    
    Process{
        $CsCdHostsSubnet = $ScCdHostsTemplate.Where{$_.NIC.Network.Name -eq $Subnet.Name}
        Foreach ($Node in $CsCdHostsSubnet){
            $Node.NIC.Network.IPAddress = Get-IPNodeAddress -SubnetAddress $Subnet.NetworkAddress -PrefixLenghth $Subnet.PrefixLength -NodePosition $CsCdHostsSubnet.NIC.Network.Position
            $Node
        }
    }
}