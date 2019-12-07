#!powershell

# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#This script is to retrieve compliance

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

$params = Parse-Args $args -supports_check_mode $true
<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.153
	 Created on:   	14/08/2018 4:52 PM
	 Created by:   	weiyentan
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>



$result = @{
changed = $False
}
$comp = "apfw_$env:COMPUTERNAME"

$testpathstatusfile = Test-Path "$env:windir\temp\apfw_$env:computername.xml"

if ($testpathstatusfile)
{
	try
	{
		Remove-Item "$env:windir\temp\apfw_$env:computername.xml" -ErrorAction Stop
		$result.changed = $true
		Exit-Json $result "The file apfw_$env:windir\$comp.xml has been deleted "
	}
	catch
	{
	Fail-Json $result "The file could not be deleted "		
	}
	
	
}
else
{
	Exit-Json $result "The file $env:windir\$comp.xml does not exist or has already been deleted."
	
}
