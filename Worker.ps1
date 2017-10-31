#---------------------------------------------------------------------------------------------------------------------
# Description
#---------------------------------------------------------------------------------------------------------------------
<#
	Author: Nilesh Mali
	Created Date: 27th Oct 2017
	Updated Date: 27th Oct 2017
	Desc: A module to represent RWT Worker
#>

#---------------------------------------------------------------------------------------------------------------------
# Modules import section
#---------------------------------------------------------------------------------------------------------------------
$cwd = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Import-Module $cwd"\Browser\Browser.psm1"
Import-Module $cwd"\RabbitMQ\RMQClient.psm1"

#---------------------------------------------------------------------------------------------------------------------
# Class Definition with Data Members
#---------------------------------------------------------------------------------------------------------------------
$Worker = New-Object PsObject -Property @{
	browser = $null
	rmqClient = $null
	sessionLogsLocation = "C:\URLLogs"
}

#---------------------------------------------------------------------------------------------------------------------
# A Constructor
#---------------------------------------------------------------------------------------------------------------------
Function Worker {
	$worker = $Worker.PsObject.Copy()
	$worker.browser = Browser -application 'IE'
	$worker.rmqClient = RMQClient -hostname "10.219.240.76" -username "admin" -password "Admin123"
	$worker
}

#---------------------------------------------------------------------------------------------------------------------
# Helper Functions
#---------------------------------------------------------------------------------------------------------------------
function ConvertTo-Json20([object] $item){
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    return $ps_js.Serialize($item)
}

#---------------------------------------------------------------------------------------------------------------------
function ConvertFrom-Json20([object] $item){ 
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer

    #The comma operator is the array construction operator in PowerShell
    return ,$ps_js.DeserializeObject($item)
}

#---------------------------------------------------------------------------------------------------------------------
# Member Functions
#---------------------------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------------------------
$Worker | Add-Member -MemberType ScriptMethod -Name "GetOrWaitForJob" -Value {
	$this.rmqClient.InitConsumer( "rwt", "virtual.capture", "topic", "capture", "Norton" )
	$msg = $this.rmqClient.GetMessage()
	return ConvertFrom-Json20( $msg )
}

#---------------------------------------------------------------------------------------------------------------------
$Worker | Add-Member -MemberType ScriptMethod -Name "ProcessMessage" -Value {
	param( [parameter(Mandatory=$true)][String] $url )
	$this.browser.BeginSession( $url, $this.sessionLogsLocation, 120 )
}

#---------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------
$worker = Worker
$msg_hash = $worker.GetOrWaitForJob()
$url = $msg_hash.Item('url')
write-host $url
$worker.ProcessMessage( $url )
