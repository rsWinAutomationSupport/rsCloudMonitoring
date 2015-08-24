function Get-DefaultChecks{
    param(
        $Check,
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
    if((-not $DefaultChecks.name -contains $Check) -and ($ValidateParameters)){
        Return $false
    }
    elseif(($DefaultChecks.name -contains $Check) -and ($ValidateParameters)){Return $true}
    elseif($ReturnChecks){
        Return $DefaultChecks
    }
} 

function Get-TargetResource{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param(
		[ValidateScript({Get-DefaultChecks $_ -ValidateParameters})]
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
		[ValidateScript({Get-DefaultChecks $_ -ValidateParameters})]
		[String[]]$LoadDefaults,

		[String[]]$CustomChecks
	)
	$SourceURL = "https://raw.githubusercontent.com/rsWinAutomationSupport/rsCloudMonitoring/rsConfigureMaaSAgent/rsCloudMonitoring/DSCResources/Default_templates/RS_Default_"
	$MaaSConfigDIR = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\RS_Default_"
	$LocalChecksPath = "C:\Program Files\WindowsPowerShell\Modules\rsCloudMonitoring\RS_Default_Checks"
	$TestLocal = Get-ChildItem $LocalChecksPath
	
	if ($TestLocal -eq $null){
		# Download files From Github
		foreach($Check in Get-DefaultChecks -ReturnChecks){
			$Source = $SourceURL + $Check + ".yml"
			$Destination = $MaaSConfigDIR + $Check + ".yml"

			Write-Verbose "Downloading $Check from $Source to $Destination."
			$Downloader = new-object System.Net.WebClient
			$Downloader.DownloadFile($Source, $Destination)
		}
	}
	else{
		# Copy Rackspace files from Module directory
		Copy-Item $LocalChecksPath $MaaSConfigDIR -recurse -ErrorAction SilentlyContinue
	}

	# Download any custom checks
	If ($CustomChecks -ne $null){
		foreach ($FullURL in $CustomChecks){
			$Source = $FullURL
			$Filename = $FullURL.Substring($FULLURL.LastIndexOf("/") + 1)
			$Destination = $MaaSConfigDIR + $Filename

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
		[ValidateScript({Get-DefaultChecks $_ -ValidateParameters})]
		[String[]]$LoadDefaults,

		[String[]]$CustomChecks
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