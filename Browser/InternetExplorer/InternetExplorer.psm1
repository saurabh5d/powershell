#---------------------------------------------------------------------------------------------------------------------
# Description
#---------------------------------------------------------------------------------------------------------------------
<#
	Author: Nilesh Mali
	Created Date: 15th Sept 2017
	Updated Date: 18th Sept 2017
	Desc: A module to control ineternet explorer using its COM
#>

#---------------------------------------------------------------------------------------------------------------------
# Modules import section
#---------------------------------------------------------------------------------------------------------------------
$cwd = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Import-Module $cwd"\Clicker.psm1"

#---------------------------------------------------------------------------------------------------------------------
# A class definition with Data Members
#---------------------------------------------------------------------------------------------------------------------
$InternetExplorer = New-Object PsObject -Property @{
	application = new-object -com InternetExplorer.Application
	clicker = Clicker
}

#---------------------------------------------------------------------------------------------------------------------
# A constructor
#---------------------------------------------------------------------------------------------------------------------
Function InternetExplorer {
	$ie = $InternetExplorer.PsObject.Copy()
	$ie
}

#---------------------------------------------------------------------------------------------------------------------
# Member functions
#---------------------------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------------------------
$InternetExplorer | Add-Member -MemberType ScriptMethod -Name "BeginNavigation" -Value {
	param( [Parameter(Mandatory=$true)][String] $url )
	$this.application.Visible = $true
	#$this.application.Silent = $true
	$status = $this.application.Navigate( $url )
	$status
}

#---------------------------------------------------------------------------------------------------------------------
$InternetExplorer | Add-Member -MemberType ScriptMethod -Name "AbortNavigation" -Value {
	$status = $this.application.Stop()
	$status
}

#---------------------------------------------------------------------------------------------------------------------
$InternetExplorer | Add-Member -MemberType ScriptMethod -Name "WaitUntilBusyOrTimeout" -Value {
	param( [Parameter(Mandatory=$true)][int] $secondsToWait )
	$startTime = (GET-DATE)
	$elapsedSeconds = $null
	while( $this.application.Busy ) {
		start-sleep -m 100
		$elapsedSeconds = [int] ( New-TimeSpan -Start $startTime -End (GET-DATE) ).TotalSeconds
		if( $elapsedSeconds -ge $secondsToWait ) {
			break
		}
	}
	$elapsedSeconds
}

#---------------------------------------------------------------------------------------------------------------------
$InternetExplorer | Add-Member -MemberType ScriptMethod -Name "WaitUntilLoadedOrTimeout" -Value {
	param(  [Parameter(Mandatory=$true)][int] $secondsToWait )
	
	$startTime = (GET-DATE)
	$elapsedSeconds = [int] ( New-TimeSpan -Start $startTime -End (GET-DATE) ).TotalSeconds
	while( $elapsedSeconds -le $secondsToWait )
	{
		if( $this.application.ReadyState -eq 4 -or $this.application.ReadyState -eq 0 )
		{
			start-sleep -s 5
			break
		}
		start-sleep -m 100
		$elapsedSeconds = [int] ( New-TimeSpan -Start $startTime -End (GET-DATE) ).TotalSeconds
	}
	$elapsedSeconds
}

#---------------------------------------------------------------------------------------------------------------------
$InternetExplorer | Add-Member -MemberType ScriptMethod -Name "SavePage" -Value {
	param( [Parameter(Mandatory=$true)][String] $toFile )
	write-host "Writing to file" $toFile
	"URL:" + $this.application.LocationURL     | Out-File -FilePath $toFile
	"Title:" + $this.application.LocationName        | Out-File -FilePath $toFile -append
	"Content:" + $this.application.Document.documentElement.innerText | Out-File -FilePath $toFile -append
	#$this.application.Document.body.innerText   #.GetElementsByTagName('body').outerHTML
}

#---------------------------------------------------------------------------------------------------------------------
$InternetExplorer | Add-Member -MemberType ScriptMethod -Name "LaunchURL" -Value {
	param( [Parameter(Mandatory=$true)][String] $url, [Parameter(Mandatory=$true)][String] $toDir, [Parameter(Mandatory=$true)][int] $secondsToWait = 120 )
	$status = $this.BeginNavigation( $url )
	
	$elapsedSeconds = $this.WaitUntilBusyOrTimeout( $secondsToWait )
	if($elapsedSeconds -ge $secondsToWait)
	{
		write-host "Been busy for" $elapsedSeconds "seconds; terminating..."
		$status = $this.AbortNavigation()
	}
	else
	{
		$elapsedSeconds = $this.WaitUntilLoadedOrTimeout( $secondsToWait ) #, 
		if( $elapsedSeconds -le $secondsToWait )
		{
			if( $this.application.ReadyState -eq 0) {
				write-host "Call file saver/runner here..."
				$this.clicker.Activate( 14 )
			}
			
			if( $this.application.ReadyState -eq 4) {
				$this.SavePage( [System.IO.Path]::Combine( $toDir, "PageDetails.txt" ) )
			}
		}
		$status = $true
	}
	
	$status
}

#---------------------------------------------------------------------------------------------------------------------
# End of Module
#---------------------------------------------------------------------------------------------------------------------