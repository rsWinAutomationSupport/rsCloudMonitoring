function ExtractAPIKey([pscredential]$apiKey){
    Return $apiKey.GetNetworkCredential().Password
}
<#function Get-AuthServices {
    param(
        $userName,
        $apiKey
    )

    $identityURI = "https://identity.api.rackspacecloud.com/v2.0/tokens"
    $credJson = @{"auth" = @{"RAX-KSKEY:apiKeyCredentials" =  @{"username" = $userName; "apiKey" = $apiKey}}} | convertTo-Json
    $catalog = Invoke-RestMethod -Uri $identityURI -Method POST -Body $credJson -ContentType application/json
    $authToken = @{"X-Auth-Token"=$catalog.access.token.id}
    return $authToken,$catalog
}
function Get-ServiceCatalog{
    param(
        $cloudRegion=$null,
        $cloudService=$null,
        $serviceCatalog
    )
    
    $endpoints = ($serviceCatalog.access.servicecatalog | where name -eq $cloudService).endpoints
    if($endpoints.count -gt 1){
        Return ($endpoints | where region -eq $cloudRegion).publicURL
    }
    else{
        Return $endpoints.publicURL
    }
}
function EntityManager{
    param(
        $authToken,
        $publicURL,
        $entityLabel
    )

    $publicURL += "/entities"
    $entityInfo = Invoke-RestMethod -Uri $publicURL -Method Get -Headers $authToken -ContentType application/json
    if(($entityInfo.values | ? label -eq $entityLabel) -eq $null){
        Write-Verbose "The entity $($entityLabel) does not exist in cloud intelligence and it will be created"
        Invoke-RestMethod -Uri $publicURL -Method Post -Headers $authToken -Body (@{"label"=$entityLabel} | ConvertTo-Json) -ContentType application/json
    }
}#>
function Get-TargetResource{
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        $userName,
        [ValidateNotNullOrEmpty()]
        [pscredential]$apikey
    )

    @{
        "username" = $userName
    }
}
function Test-TargetResource{
    [OutputType([boolean])]
    param(
        [Parameter(Mandatory = $true)]
        $userName,
        [ValidateNotNullOrEmpty()]
        [pscredential]$apikey
    )

    Write-Verbose "Validating that the Rackspace Cloud Monitoring Agent is present and running"
    $servicePresent = Get-Service 'Rackspace Cloud Monitoring Agent' -ErrorAction SilentlyContinue
    if($servicePresent.Status -ne "Running"){$servicePresent = $null}

    Write-Verbose "Validating the config file is present and not empty"
    if(Test-Path 'C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.cfg'){
        $configPresent = $null
        $configPresent = gc 'C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.cfg'
    }
    else{$configPresent = $null}

    if(($servicePresent -ne $null) -and ($configPresent -ne $null)){Return $true}
    else{Return $false}
}
function Set-TargetResource{
    param(
        [Parameter(Mandatory = $true)]
        $userName,
        [ValidateNotNullOrEmpty()]
        [pscredential]$apikey,
        $entityLabel
    )

    [string]$apikey = ExtractAPIKey $apikey
    <#$authInfo = Get-AuthServices -userName $userName -apiKey $apikey
    $authToken = $authInfo[0]
    $publicURL = Get-ServiceCatalog -cloudService cloudMonitoring -serviceCatalog $authInfo[1]
    if($entityLabel -eq $null){
        $entityLabel = $env:COMPUTERNAME
    }
    EntityManager -authToken $authToken -publicURL $publicURL -entityLabel $entityLabel#>

    if(Test-Path "C:\Program Files\Rackspace Monitoring"){$binPath = "C:\Program Files\Rackspace Monitoring\rackspace-monitoring-agent.exe"}
    elseif(Test-Path "C:\Program Files (x86)\Rackspace Monitoring"){$binPath = "C:\Program Files (x86)\Rackspace Monitoring\rackspace-monitoring-agent.exe"}
    else{throw "Monitoring Agent Executable not located on this system. Please ensure the package has been deployed and rerun this configuration"}
    $dowhat = "--setup --username $($userName) --apikey $($apikey)"

    Write-Verbose "Executing MaaS agent configuration to register the agent with Cloud Intelligence"
    Write-Verbose "Executing: $($binPath) --auto-create-entity --setup --username $($userName) --apikey $($apikey)"
    & $binPath --auto-create-entity --setup --username $($userName) --apikey $($apikey) | Out-File C:\maas_configure.txt
    Write-Verbose "LASTEXITCODE: $($LASTEXITCODE)"
    if(((Get-Content C:\maas_configure.txt).Contains("Agent successfuly connected!")) -and ($LASTEXITCODE -eq 0)){
        Write-Verbose "Agent was sucessfully registered to cloud Monitoring"
        Restart-Service 'Rackspace Monitoring Agent'
    }
    else{
        throw "Error registering MaaS agent. Please check C:\maas_configure.txt for errors"
    }
}