function Get-DefaultChecks{
    param(
        $Check,
        [switch]$ValidateParameters = $false,
        [switch]$ReturnCheckNames = $false,
        [switch]$ReturnCheckInfo = $false
    )
    # This fuctions gets the check info from Git, it does not check locally.

    Write-Verbose "Get-DefaultChecks - Current check: $Check."
    try{
        $DefaultChecks = Invoke-restmethod -Uri "https://raw.githubusercontent.com/rsWinAutomationSupport/rsCloudMonitoring/rsConfigureMaaSAgent/DSCResources/rsConfigureMaaSAgent/DefaultChecks.json" -ContentType application/json
    }
    catch{
        throw "Unable to reach remote file: DefaultChecks.json. Please verify the file exists, and that this machine has a connection to the internet."
    }
    # If the check is unknown return false.
    if(($DefaultChecks -notmatch $Check) -and ($ValidateParameters)){
        Write-Verbose "Check is unknown returning False."
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

function Get-NICName{
    Write-Verbose "Checking for Rackconnect"
    $RackConCHK = Get-NetAdapter | ? Status -eq "Not Present"

    if($RackConCHK.name -eq "unused"){
        Write-Verbose "This server is Rackconnected."
        $NicUp = Get-NetAdapter | ? Status -eq "up"
        $NICName = ($NicUp | ? Name -Like "private*").Name

        Write-Verbose "Returning Private NIC name $NICName."
        return $NICName
    }
    Else{
        Write-Verbose "Rackconnected not detected."
        # Get the NIC cards that are in an up status, to prevent adding a disabled NIC name into a check.
        $NicUp = Get-NetAdapter | ? Status -eq "up"
        # Get the Puclic NIC name
        $NICName = ($NicUp | ? Name -Like "public*").Name

        Write-Verbose "Returning Public NIC name $NICName."
        return $NICName
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
    $MaaSConfigDIR = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d"

    if ($TestLocal -eq $null){
        # This section runs if no checks are found in the module path.
        Write-Verbose "Checks NOT found in $LocalChecksPath. Will download all checks."
        foreach($Check in $LoadDefaults){
            $Source = (Get-DefaultChecks -Check $Check -ReturnCheckInfo).ConfigURL
            $Destination = (Get-DefaultChecks -Check $Check -ReturnCheckInfo).ConfigPath

            Write-Verbose "Downloading $Check from $Source to $Destination."

            Try{
                # Attempt download of check
                $Downloader = new-object System.Net.WebClient
                $Downloader.DownloadFile($Source, $Destination)
            }
            catch{
                # Download failed
                Throw "Unable to download $Source file. Please check internet connection."
            }
        }
    }
    else{
        # This section run when the needed checks are found in the module path. The checks get copied to correct locaiton.
        foreach($Check in $LoadDefaults){
            $CheckFileDest = (Get-DefaultChecks -Check $Check -ReturnCheckInfo).ConfigPath
            $CheckFileSource = (Get-DefaultChecks -Check $Check -ReturnCheckInfo).LocalURL

            Write-Verbose "Copying Source = $CheckFileSource to Desination = $CheckFileDest"
            Copy-Item $CheckFileSource $CheckFileDest -ErrorAction SilentlyContinue
        }
    }

    # Download any custom checks
    If ($CustomChecks -ne $null){
        foreach ($FullURL in $CustomChecks){
            $CCSource = $FullURL
            # Get just the filename from the URL and place in variable.
            $CCFilename = $FullURL.Substring($FULLURL.LastIndexOf("/") + 1)

            # Assemble full file path for the custom check
            $CCDestination = $MaaSConfigDIR + "\" + $CCFilename

            Try{
                # Attempt download of check
                Write-Verbose "Downloading Custom check $CCFilename from $CCSource to $CCDestination."
                $Downloader = new-object System.Net.WebClient
                $Downloader.DownloadFile($CCSource, $CCDestination)
            }
            Catch{
                #Download failed
                Throw "Unable to download custom check $CCSource file. Please check internet connection and verfiy custom check URL."
            }
        }
    }

    # Update the Public NIC name in checks
    $NICName = Get-NICName
    $Checks = (Get-ChildItem $MaaSConfigDIR).Name

    Write-Verbose "The Public NIC name returned is: $NICName"

    foreach($CHKsToUpdate in $Checks){

        Write-Verbose "Current check is: $CHKsToUpdate"

        # Only need to make changes to the Network check others will be ignored.
        If($CHKsToUpdate -eq "RS_Default_Network.yaml"){
            # Assemble the current check file path.
            $CheckPath = $MaaSConfigDIR + "\" + $CHKsToUpdate
            Write-Verbose "Will update check: $CheckPath."

            Try{
                # Replace %public% in the check with the proper NIC name.
                (Get-Content $CheckPath).Replace("%public%", $NICName) | Set-Content $CheckPath
                Write-Verbose "The NIC name has been set to $NICName in $CHKsToUpdate."
            }
            Catch{
                Throw "Failed to update: $CheckPath"
            }
        }
        Else{
            Write-Verbose "The check $CHKsToUpdate will not be updated."
        }
    }

    # Restart Agent
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