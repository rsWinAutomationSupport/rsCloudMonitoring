function Get-TargetResource{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param(
		[ValidateSet("UsedDiskSpace","Ping","LoadAVG", "All")]
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
		[ValidateSet("UsedDiskSpace","Ping","LoadAVG", "All")]
		[String[]]$LoadDefaults = $null,

		[String[]]$CustomChecks = $null
	)
	$SourceURL = "https://raw.githubusercontent.com/rsWinAutomationSupport/rsCloudMonitoring/rsConfigureMaaSAgent/rsCloudMonitoring/DSCResources/Default_templates/RS_Default_"
	$MaaSConfigDIR = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\RS_Default_"
	$LocalChecksPath = "C:\Program Files\WindowsPowerShell\Modules\rsCloudMonitoring\RS_Default_Checks"
	$TestLocal = Get-ChildItem $LocalChecksPath
	
	if ($TestLocal -eq $null){
		# Download files From Github
		foreach ($Check in $LoadDefaults){
			$Source = $SourceURL + $Check + ".yml"
			$Destination = $MaaSConfigDIR + $Check + ".yml"

			Write-Verbose "Downloading $check from $Source to $Destination."
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
		[ValidateSet("UsedDiskSpace","Ping","LoadAVG", "All")]
		[String[]]$LoadDefaults = $null,

		[String[]]$CustomChecks = $null
	)
	$MaaSConfigDIR = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\RS_Default_"
	$LocalChecksPath = "C:\Program Files\WindowsPowerShell\Modules\rsCloudMonitoring\RS_Default_Checks"
	$MissingChecks = @()

    if($LoadDefaults -eq "All"){
        # Load all x number of checks
        foreach($Check in (gci $LocalChecksPath | ? PSIsContainer -eq $false)){
            if($Check -ne $null){
                $TargetCheck = $MaaSConfigDIR + $Check.Name
                if(!(Test-Path $TargetCheck)){
                    $MissingChecks += $check.BaseName
                }
            }
            else{
                Return $false
            }
        }
    }
    else{
        foreach($Item in $LoadDefaults){
            $TargetCheck = $TargetDirectory + $Item + ".yml"
            if(!(Test-Path $targetCheck)){
                $MissingChecks += $Item
            }
        }
    }

    if($MissingChecks.Count -gt 0){
        Return $false
    }
    else{
        Return $true
    }
}

Export-ModuleMember -Function *-TargetResource