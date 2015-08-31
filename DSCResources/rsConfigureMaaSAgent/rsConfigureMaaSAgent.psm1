function Get-DefaultChecks{
    param(
        $Check,
        [switch]$ValidateParameters = $false,
        [switch]$ReturnCheckNames = $false,
        [switch]$ReturnCheckInfo = $false
    )

    try{
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
		$LoadDefaults = Get-DefaultChecks -ReturnCheckNames | Where-object {$_ -ne "All"}
    }

	$LocalChecksPath = "C:\Program Files\WindowsPowerShell\Modules\rsCloudMonitoring\DSCResources\RS_Default_Checks"
	$TestLocal = Get-ChildItem $LocalChecksPath
	
	if ($TestLocal -eq $null){
		# Download files From Github
		foreach($Check in $LoadDefaults){
            $Source = (Get-DefaultChecks -Check $Check -ReturnCheckInfo).ConfigURL
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
            $CheckFileDest = (Get-DefaultChecks -Check $Check -ReturnCheckInfo).ConfigPath
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
		$LoadDefaults = Get-DefaultChecks -ReturnCheckNames | Where-object {$_ -ne "All"}
    }

    $MissingChecks = @()	

    foreach ($Check in $LoadDefaults){
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