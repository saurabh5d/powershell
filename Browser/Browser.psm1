#---------------------------------------------------------------------------------------------------------------------
# Description
#---------------------------------------------------------------------------------------------------------------------
<#
	Author: Nilesh Mali
	Created Date: 15th Sept 2017
	Updated Date: 18th Sept 2017
	Desc: A module to represent Browser
#>

#---------------------------------------------------------------------------------------------------------------------
# Modules import section
#---------------------------------------------------------------------------------------------------------------------
$cwd = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Import-Module $cwd"\InternetExplorer\InternetExplorer.psm1"

#---------------------------------------------------------------------------------------------------------------------
# Class Definition with Data Members
#---------------------------------------------------------------------------------------------------------------------
$Browser = New-Object PsObject -Property @{
	app = $null	# IE, Chrome object holder
}

#---------------------------------------------------------------------------------------------------------------------
# A Constructor
#---------------------------------------------------------------------------------------------------------------------
Function Browser {
	param( [Parameter(Mandatory=$false)][String] $application )
	$browser = $Browser.PsObject.Copy()
	if($application -eq "IE")
	{
		$browser.app = InternetExplorer
	}
	$browser
}

#---------------------------------------------------------------------------------------------------------------------
# Member Functions
#---------------------------------------------------------------------------------------------------------------------
$Browser | Add-Member -MemberType ScriptMethod -Name "BeginSession" -Value {
	param( [Parameter(Mandatory=$true)][String] $url, [Parameter(Mandatory=$true)][String] $sessionLogsLocation, [Parameter(Mandatory=$true)][int] $timeoutSeconds = 120 )
	$status = $this.app.LaunchURL( $url, [System.IO.Directory]::CreateDirectory( $sessionLogsLocation ).FullName, $timeoutSeconds )
}


