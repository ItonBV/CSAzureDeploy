New-Deployment{
    [Cmdletbinding()]
    Param
    (
        #Long name (15 char max) of the customer name used in domain
        [parameter(Mandatory = $true)]
        [ValidatePattern("^\w{3,15}$")]# May not be longer than NetBiosName
        [string]$CustomerName,
        #GUID or KvK number of custumer
        [parameter(Mandatory = $true)]
        #[ValidatePattern("^\w{3,15}$")]# May not be longer than NetBiosName
        [string]$CustomerID,
        [string]$AdministratorAccount,
        [SecureString]$AdministratorPassword,
        #Number of users to provision
        [parameter(Mandatory = $true)]
        [int]$Users,
        #Size of the profile disk to provision
        [int]$ProfileSize,
        #Size of homedirs provision
        [int]$HomedirSize,
        #The Fully Qualified DomainName of public/external domain, e.g.; "iton.nl".
        [parameter(Mandatory = $true)]
        [ValidatePattern("^(?=^.{1,254}$)(^(?:(?!\.|-)([a-z0-9\-\*]{1,63}|([a-z0-9\-]{1,62}[a-z0-9]))\.)+(?:[a-z]{2,})$)$")]#from regexlib.com
        [string]$PublicFQDN,
        #The Fully Qualified DomainName used for internal/private domain naming, e.g.; "test.local" or "internal.iton.nl".
        [ValidatePattern("^(?=^.{1,254}$)(^(?:(?!\.|-)([a-z0-9\-\*]{1,63}|([a-z0-9\-]{1,62}[a-z0-9]))\.)+(?:[a-z]{2,})$)$")]#from regexlib.com
        [string]$PrivateFQDN,
        #The NetBiosName of the private/internal domain.
        [ValidatePattern("^\w{3,15}$")]# May not be longer than NetBiosName
        [string]$NetBiosName = $CustomerName,
        #The ID of the private/internal network.
        [ValidateScript( {$_ -match [IPAddress]$_ })]  
        #[ValidatePattern("^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")]# from http://www.regexmagic.com/manual/xmppatternipv4.html
        [string]$PrivateNetId,
        #The mask "xxx.xxx.xxx.xxx" of the private/internal network.
        [ValidateScript( {$_ -match [IPAddress]$_ })]  
        #[ValidatePattern("^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")]# from http://www.regexmagic.com/manual/xmppatternipv4.html
        [string]$PrivateNetMask,
        #The RDS portal name for Entity. If none is given it defaults to "werkplek.$publicFQDN".
        [ValidatePattern("^(?=^.{1,254}$)(^(?:(?!\.|-)([a-z0-9\-\*]{1,63}|([a-z0-9\-]{1,62}[a-z0-9]))\.)+(?:[a-z]{2,})$)$")]#from regexlib.com
        [string]$RDSPortalName,
        #Array of strings with the entity names in domain, defaults to customer name if none given. MUST at least contain customername
        [string[]]$EntityName, # Each value may not be longer than NetBiosName (15 char max)
        #For how many users should normal rdshosts be deployed?
        [int]$rdsh = $users,
        #For how many users should premium rdshosts be deployed?
        [int]$rdsp = 0,
        #For how many users should remoteapp be deployed?
        [int]$rdsa = 0,
        #choose when a mfa server must be present
        [switch]$mfa,
        #Some constants, but available as params for tinkering
        [PSObject]$CSDefaults,
        [PSObject]$VMMDiskConfig,
        [PSObject]$VMMNetworkConfig
    )

    #region Validate (missing) params
    If (!($PrivateFQDN)) {$PrivateFQDN = "$($CSDefaults.PrivateDomainName).$($PublicFQDN)"}
    If (!($RDSPortalName)) {$RDSPortalName = "$($CSDefaults.RDSPortalName).$($PublicFQDN)"}
    If ($ProfileSize) {
        If ($CSDefaults.ProfileSize -notcontains $ProfileSize) {
            Write-Error -Message "Given profilesize is not valid, supply one of the following values: $([String]$CSDefaults.ProfileSize)"
            exit 1
        }
    }
    Else {
        $ProfileSize = $CSDefaults.ProfileSizeDefault
    }
    If (!($HomedirSize)) {$HomedirSize = $CSDefaults.DataSize}

    #Detect and/or create shortname
    If ($CustomerName.length -gt $CSDefaults.EntityShort) {$CustomerShortName = Convert-ToEntityShort -Name $CustomerName -Length $CSDefaults.EntityShort}Else {$CustomerShortName = $CustomerName}
    
    #Detect and/or create Administrator account and password
    If (!($AdministratorAccount)) {$AdministratorAccount = "$($CustomerShortName)admin"}
    #validate given password
    If (!($AdministratorPassword)) {
        $AdministratorPassword = New-RandomPassword -PasswordLength ($CSDefaults.RandomPassword.Length) -InputStrings ($CSDefaults.RandomPassword.Characters)
    }
    Else {
        $AdministratorPassword = ConvertFrom-SecureString -SecureString $AdministratorPassword
    }

    #validate CustomerEndPoint information and build Site Name domain
    $Site = $CSDefaults.EndPoint | Where-Object -Property Name -eq $CSDefaults.EndPointDefault
    $CustomerSiteName = "$($Site.Region)-$($Site.Location)"
    Write-Verbose -Message "Detected sitename $($CustomerSiteName) for deployement" 

    If ($EntityName -eq $null) {
        # for some dark reason, direct assignment within the param section does noet work(?)
        $EntityName = @($CustomerName)
    }

    #Validate if EntityName contains customername
    If ($EntityName -notcontains $CustomerName) {
        Write-Error -Message "$($CustomerName) not found in EntityName. MUST be present!"
        exit 1
    }
    #endregion Validate (missing) params

}