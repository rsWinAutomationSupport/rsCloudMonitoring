function ExtractAPIKey([pscredential]$apiKey){
    Return $apiKey.GetNetworkCredential().Password
}
function Get-TargetResource{
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        $userName,
        [ValidateNotNullOrEmpty()]
        [pscredential]$apikey
    )
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
        [pscredential]$apikey
    )

    $apikey = ExtractAPIKey $apikey
    if(Test-Path "C:\Program Files\Rackspace Monitoring"){$binPath = "C:\Program Files\Rackspace Monitoring\rackspace-monitoring-agent.exe"}
    elseif(Test-Path "C:\Program Files (x86)\Rackspace Monitoring"){$binPath = "C:\Program Files (x86)\Rackspace Monitoring\rackspace-monitoring-agent.exe"}
    else{throw "Monitoring Agent Executable not located on this system. Please ensure the package has been deployed and rerun this configuration"}
    $dowhat = "--setup --username $($userName) --apikey $($apikey)"

    Write-Verbose "Executing MaaS agent configuration to register the agent with Cloud Intelligence"
    Write-Verbose "Executing: $($binPath) $($dowhat)"
    Start-Process $binPath $dowhat -Wait -NoNewWindow
}