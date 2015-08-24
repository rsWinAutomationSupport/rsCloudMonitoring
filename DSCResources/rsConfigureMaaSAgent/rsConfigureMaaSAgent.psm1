function Get-DefaultChecks{
    param(
        $check,
        [switch]$ValidateParameters = $false,
        [switch]$ReturnChecks = $false
    )

    $notValid = @()
    try{
        $DefaultChecks = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rsWinAutomationSupport/rsCloudMonitoring/rsConfigureMaaSAgent/DSCResources/rsConfigureMaaSAgent/DefaultChecks.json" | select -exp Content | ConvertFrom-Json
    }
    catch{
        throw "Unable to complete request to requested file at this time. Please verify this machine's internet access and try again"
    }
    if((-not $DefaultChecks.name -contains $check) -and ($ValidateParameters)){
        Return $false
    }
    elseif(($DefaultChecks.name -contains $check) -and ($ValidateParameters)){Return $true}
    elseif($ReturnChecks){
        Return $DefaultChecks
    }
} 

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
			$Downloader.DownloadFile($Source, $Destination)
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
			$Downloader.DownloadFile($Source, $Destination)
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
		[String[]]$RsDefaultCheckNames = @("UsedDiskSpace","Ping","LoadAVG"),

		[String[]]$CustomChecks = $null
	)
	$MaaSConfigDIR = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\RS_Default_"
	$LocalChecksPath = "C:\Program Files\WindowsPowerShell\Modules\rsCloudMonitoring\RS_Default_Checks"
    $MissingChecks = @()	

    foreach ($RsDefaultCheck in $RsDefaultCheckNames){
        $CheckTarget = $MaaSConfigDIR + $RsDefaultCheck + ".yml"
        $DefaultCheck = $null
		$DefaultCheck = gc $CheckTarget
        if(!(Test-Path $CheckTarget)){
            $MissingChecks += $RsDefaultCheck
        }   
    }

    if($MissingChecks.Count -gt 0){
        Return $false
    }
    else{
        Return $true
    }
}