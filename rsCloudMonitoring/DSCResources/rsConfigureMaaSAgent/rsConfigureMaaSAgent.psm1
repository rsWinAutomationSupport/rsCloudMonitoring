function Get-TargetResource{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param(
		[ValidateSet("UsedDiskSpace","Ping","LoadAVG")]
		[String[]]$LoadDefaults,

		[String[]]$CustomChecks
	)
        $returnValue = @{
		"LoadDefaults" = $LoadDefaults
		"CustomChecks" = $CustomChecks
	}
}

function Set-TargetResource{
	[CmdletBinding()]
	param(
		[ValidateSet("UsedDiskSpace","Ping","LoadAVG")]
		[String[]]$LoadDefaults = $null,

		[String[]]$CustomChecks = $null
	)
    $SourceURL = "https://raw.githubusercontent.com/rsWinAutomationSupport/rsCloudMonitoring/rsConfigureMaaSAgent/rsCloudMonitoring/DSCResources/Default_templates/RS_Default_"
    $TargetDiretory = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\RS_Default_"
    $LocalChecksPath = "C:\Program Files\WindowsPowerShell\Modules\rsCloudMonitoring\RS_Default_Checks"
    $TestLocal = Get-ChildItem $LocalChecksPath
	
    if ($TestLocal -eq $null){
		# Download files From Github
		foreach ($Check in $LoadDefaults){
			$Source = $SourceURL + $Check + ".yml"
			$Destination = $TargetDiretory + $Check + ".yml"

			Write-Verbose "Downloading $check from $Source to $Destination."
			$Downloader = new-object System.Net.WebClient
			$Downloader.DownloadFile($Source, $Desination)
		}
	}
	else{
		# Copy Rackspace files from Module directory
		Copy-Item $LocalChecksPath $TargetDiretory -recurse -ErrorAction SilentlyContinue
	}
	
	# Download any custom checks
	If ($CustomChecks -ne $null){
		foreach ($FullURL in $CustomChecks){
			$Source = $FullURL
			$Filename = $FullURL.Substring($FULLURL.LastIndexOf("/") + 1)
			$Destination = $TargetDiretory + $Filename

			Write-Verbose "Downloading $Filename from $Source to $Destination."
			$Downloader = new-object System.Net.WebClient
			$Downloader.DownloadFile($Source, $Desination)
	    }
    }
	
	#Restart Agent
	Restart-Service 'Rackspace Monitoring Agent' -ErrorAction SilentlyContinue
}

function Test-TargetResource{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param(
        [ValidateSet("UsedDiskSpace","Ping","LoadAVG")]
		[String[]]$LoadDefaults = $null,

		[String[]]$CustomChecks = $null
	)
	$TargetDiretory = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\RS_Default_"
	$LocalChecksPath = "C:\Program Files\WindowsPowerShell\Modules\rsCloudMonitoring\RS_Default_Checks"
    $Target1 = $TargetDiretory + $LoadDefaults[0] + ".yml"
	$Target2 = $TargetDiretory + $LoadDefaults[1] + ".yml"
	$Target3 = $TargetDiretory + $LoadDefaults[2] + ".yml"

	Write-Verbose "Check to see if RS default checks are in place and not empty"

	# Checking RS_Default_UsedDiskSpace.yml
	if(Test-Path $Target1){
		$DefaultCHK1 = $null
		$DefaultCHK1 = gc $Target1
	}
	else{$DefaultCHK1 = $null}

	# Checking RS_Default_Ping.yml
	if(Test-Path $Target2){
		$DefaultCHK2 = $null
		$DefaultCHK2 = gc $Target2
	}
	else{$DefaultCHK2 = $null}

	# Checking RS_Default_LoadAVG.yml
	if(Test-Path $Target3){
		$DefaultCHK3 = $null
		$DefaultCHK3 = gc $Target3
	}
	else{$DefaultCHK3 = $null}

	# Test to see if RS defalt checks match local copy
	$MatchTest1 = Get-ChildItem -Recurse $LocalChecksPath
	$MatchTest2 = Get-ChildItem -Recurse $TargetDiretory.Substring(0,77)
	$MatchResult = $null
	$MatchResult = Compare-Object $MatchTest1 $MatchTest2 -Property Name, Length

	# If all default checks are in place and have content return true else false
	if(($DefaultCHK1 -ne $null) -and ($DefaultCHK2 -ne $null) -and ($DefaultCHK3 -ne $null) -and ($MatchResult -eq $null)){Return $true}
	else{Return $false}

}

Export-ModuleMember -Function *-TargetResource