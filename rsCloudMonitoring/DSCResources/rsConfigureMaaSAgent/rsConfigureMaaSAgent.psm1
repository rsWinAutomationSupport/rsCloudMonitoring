function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SourcePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$ConfigPath
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."
	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."


	$returnValue = @{
		SourcePath = "C:\DevOps\~~~~~"
		ConfigPath = "C:\ProgramData\Rackspace Monitoring\config\rackspace-monitoring-agent.conf.d\"
		Ensure = [System.String]
		SMBPath = [System.String]
	}

	$returnValue
	
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SourcePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$ConfigPath,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.String]
		$SMBPath
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."




}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SourcePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$ConfigPath,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.String]
		$SMBPath
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."


	<#
	$result = [System.Boolean]
	
	$result
	#>
}


Export-ModuleMember -Function *-TargetResource

