function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Check1Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Check2Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Check3Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$SourceURL,

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetDiretory
	)
	$returnValue = @{
		"Check1Name" = $Check1Name
		"Check2Name" = $Check2Name
		"Check3Name" = $Check3Name
		"SourceURL" = $SourceURL
		"TargetDiretory" = $TargetDiretory
	}
}

function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
        [parameter(Mandatory = $true)]
		[System.String]
		$Check1Name = "RS_Default_UsedDiskSpace.yml",

		[parameter(Mandatory = $true)]
		[System.String]
		$Check2Name = "RS_Default_Ping.yml",

		[parameter(Mandatory = $true)]
		[System.String]
		$Check3Name = " RS_Default_LoadAVG.yml",

		[parameter(Mandatory = $true)]
		[System.String]
		$SourceURL = "https://raw.githubusercontent.com/rsWinAutomationSupport/rsCloudMonitoring/rsConfigureMaaSAgent/rsCloudMonitoring/DSCResources/Default_templates/",

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetDiretory = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\"
	)
	    
    try{
        #Copy files from Module directory
        $ModuleDir = "C:\Program Files\WindowsPowerShell\Modules\rsCloudMonitoring\RS_Default_Checks"

        Copy-Item $ModuleDir $TargetDiretory -recurse

    }
    catch {
        #Download files From Github
        $CheckNames = ($Check1Name, $Check2Name, $Check3Name)
	    foreach ($Check in $CheckNames){
		    $Source = $SourceURL + $Check
		    $Destination = $TargetDiretory + $Check

		    if ( -not (Test-Path $Destination))
		    {
			    Write-Verbose "Downloading $check from $Source to $Destination."
			    $Downloader = new-object System.Net.WebClient
			    $Downloader.DownloadFile($Source, $Desination)
		    }
	    }
    }

	#Restart Agent
	Write-EventLog -LogName DevOps -Source rsCloudMonitoring -EntryType Information -EventId 1000 -Message ("Restarting Rackspace Cloud Monitoring Agent")
	try {
		if ( (get-service "Rackspace Cloud Monitoring Agent").Status -eq 'Running' ) { Stop-service "Rackspace Cloud Monitoring Agent" }
	}
	catch {
		Write-EventLog -LogName DevOps -Source rsCloudMonitoring -EntryType Error -EventId 1000 -Message "Failed to Stop RackSpace Cloud Monitoring Agent `n $($_.Exception.Message)"
	}
	try {
		if ( (get-service "Rackspace Cloud Monitoring Agent").Status -ne 'Running' ) { Start-service "Rackspace Cloud Monitoring Agent" }
	}
	catch {
		Write-EventLog -LogName DevOps -Source rsCloudMonitoring -EntryType Error -EventId 1000 -Message "Failed to Start RackSpace Cloud Monitoring Agent `n $($_.Exception.Message)"
	}
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Check1Name = "RS_Default_UsedDiskSpace.yml",

		[parameter(Mandatory = $true)]
		[System.String]
		$Check2Name = "RS_Default_Ping.yml",

		[parameter(Mandatory = $true)]
		[System.String]
		$Check3Name = "RS_Default_LoadAVG.yml",

		[parameter(Mandatory = $true)]
		[System.String]
		$SourceURL = "https://raw.githubusercontent.com/rsWinAutomationSupport/rsCloudMonitoring/rsConfigureMaaSAgent/rsCloudMonitoring/DSCResources/Default_templates/",

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetDiretory = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\"
	)
    $LocalChecksPath = "C:\Program Files\WindowsPowerShell\Modules\rsCloudMonitoring\RS_Default_Checks"
	$Target1 = $TargetDiretory + $Check1Name
	$Target2 = $TargetDiretory + $Check2Name
	$Target3 = $TargetDiretory + $Check3Name

	Write-Verbose "Check to see if default checks are in place and not empty"

	# Checking UsedDiskSpace.yml
	if(Test-Path $Target1){
		$DefaultCHK1 = $null
		$DefaultCHK1 = gc $Target1
	}
	else{$DefaultCHK1 = $null}

	# Checking Ping.yml
	if(Test-Path 'C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\Ping.yml'){
		$DefaultCHK2 = $null
		$DefaultCHK2 = gc $Target2
	}
	else{$DefaultCHK2 = $null}

	# Checking LoadAVG.yml
	if(Test-Path 'C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\LoadAVG.yml'){
		$DefaultCHK3 = $null
		$DefaultCHK3 = gc $Target3
	}
	else{$DefaultCHK3 = $null}

    # Compair if content matches
    $MatchTest1 = Get-ChildItem -Recurse $localTestPath
    $MatchTest2 = Get-ChildItem -Recurse $TargetDiretory
    $MatchResult = $null
    $MatchResult = Compare-Object $testDiff1 $testDiff2 -Property Name, Length

	# If all default checks are in place and have content return true else false
	if(($DefaultCHK1 -ne $null) -and ($DefaultCHK2 -ne $null) -and ($DefaultCHK3 -ne $null) -and ($Result -eq $null)){Return $true}
	else{Return $false}
}
Export-ModuleMember -Function *-TargetResource