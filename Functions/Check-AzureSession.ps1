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
