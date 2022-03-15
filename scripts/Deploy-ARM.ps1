param(
    [Parameter(Mandatory=$true)][string]$AzureSubscriptionName="",
    [Parameter(Mandatory=$true)][string]$ResourceGroupName="",
    [Parameter(Mandatory=$true)][string]$GUAC_LOCATION="",
    
    [Parameter(Mandatory=$true)][string]$AadWebClientId="",
    [Parameter(Mandatory=$true)][string]$AadWebClientAppKey="",
    [Parameter(Mandatory=$true)][string]$AadTenantId="",

    [Parameter(Mandatory=$true)][string]$FullDeploymentArmTemplateFile="",

    [Parameter(Mandatory=$true)][string]$GUAC_NAME="",
    [Parameter(Mandatory=$true)][string]$EMAIL_TAG="",

    [Parameter(Mandatory=$false)][string]$ADDRESS_SPACE_PREFIXES="10.0.0.0/16",
    [Parameter(Mandatory=$false)][string]$SUBNET_ADDRESS_PREFIXES="10.0.0.0/24",

    [Parameter(Mandatory=$true)][string]$ADMIN_USERNAME="",
    [Parameter(Mandatory=$true)][string]$ADMIN_SSH_KEY="",

    [Parameter(Mandatory=$false)][string]$GUAC_VM_SIZE="Standard_B2ms"

)


$azSecureApplicationKey = $AadWebClientAppKey | ConvertTo-SecureString -AsPlainText -Force
$azCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AadWebClientId, $azSecureApplicationKey
$isLoggedIn = [bool](Connect-AzAccount -Credential $azCredential -TenantId $AadTenantId -ServicePrincipal)

if($isLoggedIn){
    Select-AzSubscription -Subscription $AzureSubscriptionName
    Write-Host "Deploying Resource Group."
    New-AzResourceGroup -Name $ResourceGroupName -Location $GUAC_LOCATION -Tag @{ _contact_person=$EMAIL_TAG }
    Write-Host "Deploying Template."

    $invocation = (Get-Variable MyInvocation).Value 
    $currentPath = Split-Path $invocation.MyCommand.Path 
    $rootPath = (get-item $currentPath).parent.FullName
    $parameterPath = "$($rootPath)\templates\parametersFile.json"

    $parmeters = Get-Content -Path $parameterPath | ConvertFrom-Json

    $armParameters = @{
        'GUAC_NAME'=(&{If($GUAC_NAME) {$GUAC_NAME} Else {$parmeters.parameters.GUAC_NAME.value}})
        'GUAC_LOCATION'=(&{If($GUAC_LOCATION) {$GUAC_LOCATION} Else {$parmeters.parameters.GUAC_LOCATION.value}})

        'EMAIL_TAG'=(&{If($EMAIL_TAG) {$EMAIL_TAG} Else {$parmeters.parameters.EMAIL_TAG.value}})
        
        'ADDRESS_SPACE_PREFIXES'=(&{If($ADDRESS_SPACE_PREFIXES) {$ADDRESS_SPACE_PREFIXES} Else {$parmeters.parameters.ADDRESS_SPACE_PREFIXES.value}})
        'SUBNET_ADDRESS_PREFIXES'=(&{If($SUBNET_ADDRESS_PREFIXES) {$SUBNET_ADDRESS_PREFIXES} Else {$parmeters.parameters.SUBNET_ADDRESS_PREFIXES.value}})
        
        'ADMIN_USERNAME'=(&{If($ADMIN_USERNAME) {$ADMIN_USERNAME} Else {$parmeters.parameters.ADMIN_USERNAME.value}})
        'ADMIN_SSH_KEY'=(&{If($ADMIN_SSH_KEY) {$ADMIN_SSH_KEY} Else {$parmeters.parameters.ADMIN_SSH_KEY.value}})

        'GUAC_VM_SIZE'=(&{If($GUAC_VM_SIZE) {$GUAC_VM_SIZE} Else {$parmeters.parameters.GUAC_VM_SIZE.value}})
    }

    New-AzResourceGroupDeployment `
        -Name "GuacTemplate" `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $FullDeploymentArmTemplateFile `
        -TemplateParameterObject $armParameters

}
else {
    Write-Error "Invalid Access."
}

