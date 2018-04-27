<#
    https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-powershell-sas-token
#>
Params(
    [String]
    [IPAdrress]$NetworkAddress
    [ValidateScript({(New-Object System.Net.Mail.MailAddress($_)) -and ($_ -like "*onmicrosoft.com")})]
    [string]$SubscriptionAccount,
    [securesttring]$SubscriptionPassword,
    [string]$SubscriptionName,
    
    
)
remove-module GenericFunctions

import-module GenericFunctions
#Prepare params for deployment
$CSSubnetTempate = Get-AzureSubnetTemplate
$CSSubnets = Get-CSAzureSubnets -Network $NetworkAddress
$AzureNetworkDeploymentParameters = 

#Create the VNet
Connect-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName '<yourSubscriptionName>'
New-AzureRmResourceGroup -Name ExampleResourceGroup -Location "West Europe"
$splatParamsDeployment = @{
    Name = 'ExampleDeployment'
    ResourceGroupName = 'ExampleResourceGroup'
    TemplateUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-storage-account-create/azuredeploy.json'
}

New-AzureRmResourceGroupDeployment  
  -TemplateFile c:\MyTemplates\storage.json -storageAccountType Standard_GRS


{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "CustomerName": {
      "value": "janjanssen"
    },
    "CustomerShort": {
      "value": "jnjnss"
    }
  }
}


$CSHosts = $CSSubnets | Get-CDNodeIPs