function Get-SubnetTemplate{
    Param(
        [Parameter(Position = 0)]
        [ValidateSet('Small','Medium','Large')]
        [String]$Type = 'Medium',
        [Parameter(Position = 1)]
        [ValidateSet('Lan','Dmz','Mgt','Gw','Fw')]
        [String[]]$Exclude = 'Fw',
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]  
        [String]$Path = '..\Config\CSSubnetTemplate.json'
    )

    $SubnetTemplate = Get-JsonFile -Path $Path
    $CurrentTemplate = $SubnetTemplate | Where-Object -Property Type -eq $Type
    <#Might be made 'smarter' in future, but for now remake object
    $Property = @{}
    $CurrentTemplate[0].PSObject.Properties | ForEach-Object { $Property[$_.Name] = $_.Value }
    foreach ($Excl in $Exclude){
        If ($Property.Subnet.Name -eq $Excl){
            $Property.Subnet.Remove($Excl)
        }
       
    }
    #>
    $Subnet = $CurrentTemplate.Subnet.Where{$_.Name -notin $Exclude} 
    $ReturnInfo = @{
        Type = $CurrentTemplate.Type
        PrefixMin = $CurrentTemplate.PrefixMin
        Subnet = $Subnet
    }
    return [PSCustomObject]$ReturnInfo
}