function Get-DefaultChecks{
    param(
        $Check,
        [switch]$ValidateParameters = $false,
        [switch]$ReturnCheckNames = $false,
        [switch]$ReturnCheckInfo = $false
    )

    #$notValid = @()
    try{
        #$DefaultChecks = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rsWinAutomationSupport/rsCloudMonitoring/rsConfigureMaaSAgent/DSCResources/rsConfigureMaaSAgent/DefaultChecks.json" | select -exp Content | ConvertFrom-Json
		$DefaultChecks = Invoke-restmethod -Uri "https://raw.githubusercontent.com/rsWinAutomationSupport/rsCloudMonitoring/rsConfigureMaaSAgent/DSCResources/rsConfigureMaaSAgent/DefaultChecks.json" -ContentType application/json
    }
    catch{
        throw "Unable to reach remote file: DefaultChecks.json. Please verify the file exists, and that this machine has a connection to the internet."
    }
    if(($DefaultChecks -notmatch $Check) -and ($ValidateParameters)){
        Return $false
    }
    elseif(($DefaultChecks -match $Check) -and ($ValidateParameters)){Return $true}
    elseif($ReturnCheckNames){
        $htChecks = @{}
        $DefaultChecks | Get-Member -MemberType NoteProperty | ForEach-Object{
            $htChecks[$_] = $DefaultChecks.$_
        }
        Return $htChecks.Keys.Name
    }
    elseif($ReturnCheckInfo){
        Return $DefaultChecks.$Check
    }
}
function Get-TargetResource{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param(
		[ValidateScript({Get-DefaultChecks $_ -ValidateParameters})]
		[Parameter(Mandatory = $true)]
		[String[]]$LoadDefaults,

		[String[]]$CustomChecks
	)
    $returnValue = @{
	    LoadDefaults = $LoadDefaults
	    CustomChecks = $CustomChecks
	}
}

function Set-TargetResource{
	[CmdletBinding()]
	param(
		[ValidateScript({Get-DefaultChecks $_ -ValidateParameters})]
		[Parameter(Mandatory = $true)]
		[String[]]$LoadDefaults,

		[String[]]$CustomChecks
	)
    If ($LoadDefaults -eq "All"){
        #$LoadDefaults = Get-DefaultChecks -ReturnChecks
        #$LoadDefaults -= "All" 
		$LoadDefaults = Get-DefaultChecks -ReturnChecks | Where-object {$_ -ne "All"}
    }

	#$SourceURL = "https://raw.githubusercontent.com/rsWinAutomationSupport/rsCloudMonitoring/rsConfigureMaaSAgent/DSCResources/RS_Default_Checks/RS_Default_"
	#$MaaSConfigDIR = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\RS_Default_"
	$LocalChecksPath = "C:\Program Files\WindowsPowerShell\Modules\rsCloudMonitoring\RS_Default_Checks"
	$TestLocal = Get-ChildItem $LocalChecksPath
	
	if ($TestLocal -eq $null){
		# Download files From Github
		foreach($Check in $LoadDefaults){
			#$Source = $SourceURL + $Check + ".yml"
            $Source = (Get-DefaultChecks -Check $Check -ReturnCheckInfo).ConfigURL
			#$Destination = $MaaSConfigDIR + $Check + ".yml"
            $Destination = (Get-DefaultChecks -Check $Check -ReturnCheckInfo).ConfigPath

			Write-Verbose "Downloading $Check from $Source to $Destination."
			
            Try{
                $Downloader = new-object System.Net.WebClient
			    $Downloader.DownloadFile($Source, $Destination)
            }
            catch{
                Throw "Unable to download $Source file. Please check internet connection."
            }
		}
	}
	else{
        foreach($Check in $LoadDefaults){
            #$CheckFileDest = $MaaSConfigDIR + $Check + ".yml"
            $CheckFileDest = (Get-DefaultChecks -Check $Check -ReturnCheckInfo).ConfigPath
            #$CheckFileSource = $LocalChecksPath + "\RS_Default_" + $Check + ".yml"
            $CheckFileSource = (Get-DefaultChecks -Check $Check -ReturnCheckInfo).LocalURL

            Copy-Item $CheckFileSource $CheckFileDest -ErrorAction SilentlyContinue
        }
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
		[Parameter(Mandatory = $true)]
		[String[]]$LoadDefaults,

		[String[]]$CustomChecks
	)
    If ($LoadDefaults -eq "All"){
       # Write-Verbose $("$LoadDefaults")
		#$LoadDefaults = @{}
		$LoadDefaults = Get-DefaultChecks -ReturnChecks | Where-object {$_ -ne "All"}
        #$LoadDefaults -= "All"    
    }

    #$MaaSConfigDIR = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\RS_Default_"
	#$LocalChecksPath = "C:\Program Files\WindowsPowerShell\Modules\rsCloudMonitoring\RS_Default_Checks"
    $MissingChecks = @()	

    foreach ($Check in $LoadDefaults){
        #$CheckTarget = $MaaSConfigDIR + $Check + ".yml"
        $CheckTarget = (Get-DefaultChecks -Check $Check -ReturnCheckInfo).ConfigPath
        if(!(Test-Path $CheckTarget)){
            $MissingChecks += $Check
        }   
        elseif((Get-Content $CheckTarget) -eq $null){
            $MissingChecks += $Check
        }
    }

    if($MissingChecks.Count -gt 0){
        Return $false
    }
    else{
        Return $true
    }
}