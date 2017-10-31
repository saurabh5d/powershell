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
Import-Module $cwd"\PoshRabbit.psm1"

#---------------------------------------------------------------------------------------------------------------------
# Class Definition with Data Members
#---------------------------------------------------------------------------------------------------------------------
$RMQClient = New-Object PsObject -Property @{
	consumer = $null
	hostname = "10.219.240.76"
	username = "admin"
	password = ConvertTo-SecureString -String "Admin123" -AsPlainText -Force
}

#---------------------------------------------------------------------------------------------------------------------
# A Constructor
#---------------------------------------------------------------------------------------------------------------------
Function RMQClient {
	param( [parameter(Mandatory=$true)][String] $hostname,
			[parameter(Mandatory=$true)][String] $username,
			[parameter(Mandatory=$true)][String] $password
			)
	$rmqClient = $RMQClient.PsObject.Copy()
	$rmqClient.hostname = $hostname
	$rmqClient.username = $username
	$rmqClient.password = ConvertTo-SecureString -String $password -AsPlainText -Force
	$rmqClient
}

#---------------------------------------------------------------------------------------------------------------------
# Member Functions
#---------------------------------------------------------------------------------------------------------------------
$RMQClient | Add-Member -MemberType ScriptMethod -Name "InitConsumer" -Value {
	param( [parameter(Mandatory=$true)][String] $virtualhost,
			[parameter(Mandatory=$true)][String] $exchange,
			[parameter(Mandatory=$true)][String] $exchangetype,
			[parameter(Mandatory=$true)][String] $bindingkey,
			[parameter(Mandatory=$true)][String] $queue
			)
	$a=@{
		hostname = $this.hostname;
		exchange = $exchange;
		routingkey = $bindingkey;
		queuename = $queue;
		name = $queue;
		exchangetype = $exchangetype;
		virtualhost = $virtualhost;
		username = $this.username;
		password = $this.password;
	}
	$this.consumer = start-consumer @a
}

#---------------------------------------------------------------------------------------------------------------------
$RMQClient | Add-Member -MemberType ScriptMethod -Name "GetMessage" -Value {
	write-host "Awaiting for a job..."
	$event = $this.consumer | wait-consumer
	#$event | out-file 'msgs.txt' -append;
	([System.Text.Encoding]::ASCII).GetString( $event.Body )
}


