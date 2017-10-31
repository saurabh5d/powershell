#---------------------------------------------------------------------------------------------------------------------
# Description
#---------------------------------------------------------------------------------------------------------------------
<#
	Author: Saurabh Dube
	Created Date: 30th Oct 2017
	Updated Date: 30th Oct 2017
	Desc: A module to upload logs on FTP Server
#>
#---------------------------------------------------------------------------------------------------------------------
# Class Definition with Data Members
#---------------------------------------------------------------------------------------------------------------------
$FTPClient = New-Object PsObject -Property @{
	server = $null
	user = $null
	password = $null
}
#---------------------------------------------------------------------------------------------------------------------
# A Constructor
#---------------------------------------------------------------------------------------------------------------------
Function FTPClient {
	$ftp = $FTPClient.PsObject.Copy()
	$ftp.server = "10.219.240.159"
	$ftp.user ="Admin"
	$ftp.password="Admin123"
	$ftp
}
#---------------------------------------------------------------------------------------------------------------------
# Helper Functions
#---------------------------------------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------------------------------------
# Member Functions
#---------------------------------------------------------------------------------------------------------------------

$FTPClient | Add-Member -MemberType ScriptMethod -Name "CreateFtpDirectory" -Value {
	 param(
    [Parameter(Mandatory=$true)]
    [string]
    $sourceuri
  )
    $ftprequest = [System.Net.FtpWebRequest]::Create($sourceuri);
	$ftprequest.Credentials = New-Object System.Net.NetworkCredential($this.user,$this.password)
    $ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
    $ftprequest.UseBinary = $true

    

    $response = $ftprequest.GetResponse();

    Write-Host "File uploaded" $response.StatusDescription

    $response.Close();
}
<#function Create-FtpDirectory {
  param(
    [Parameter(Mandatory=$true)]
    [string]
    $sourceuri,
    [Parameter(Mandatory=$true)]
    [string]
    $username,
    [Parameter(Mandatory=$true)]
    [string]
    $password
  )
	
    if ($sourceUri -match '\\$|\\\w+$') { throw 'sourceuri should end with a file name' }
    $ftprequest = [System.Net.FtpWebRequest]::Create($sourceuri);
    $ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
    $ftprequest.UseBinary = $true

    $ftprequest.Credentials = New-Object System.Net.NetworkCredential($username,$password)

    $response = $ftprequest.GetResponse();

    Write-Host Upload File Complete, status $response.StatusDescription

    $response.Close();
}#>
$FTPClient | Add-Member -MemberType ScriptMethod -Name "UploadFTP" -Value {
param(
    [Parameter(Mandatory=$true)]
    [String]
    $Dir
  )  
#create WebClient object 
$webclient = New-Object System.Net.WebClient  
$webclient.Credentials = New-Object System.Net.NetworkCredential($ftp.user,$ftp.password)  
#upload every file 
foreach($item in (dir $Dir)){
	$fullname=$item.FullName
	write-host "uploading $fullname----->"
    if((Get-Item $fullname) -is [System.IO.DirectoryInfo])
	{
		
		$separator="logs\\"
		$parent=$fullname -split $separator
		$parent_f=$parent[1]
		$test=$parent_f.split("\\")
		if($test[1] -eq $null)
		{
		$localvar="ftp://"+$ftp.server+"/"+$item
		}
		else
		{
		$localvar="ftp://"+$ftp.server+"/"+$parent_f
		}
		write-host $localvar
		$this.CreateFtpDirectory($localvar)
		$this.UploadFTP($fullname)
	}
	else
	{
		$newname=$fullname.Replace("C:\logs","").Replace("\","/")
		$localvar="ftp://"+$ftp.server+$newname
		write-host $localvar
		$uri = New-Object System.Uri($localvar) 
		try{
		$webclient.UploadFile($uri,$fullname) 
		}
		catch{
		$error
		}
	}
 } 
}
<#$lines=Get-Content C:\AMCRATE\url.txt
foreach ($line in $lines) {
try{
    $path = $line -split '->'
    $fullpath=$path[1]
	$patharray=$fullpath -split '\\'
	$urlpath=$patharray[2]
	}
	catch
	{
	$error
	}
}#>
#---------------------------------------------------------------------------------------------------------------------
$ftp = FTPClient
$dir="C:/logs"  
$ftp.UploadFTP($dir)