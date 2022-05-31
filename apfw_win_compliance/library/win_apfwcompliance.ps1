#!powershell

# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#This script is to retrieve compliance

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

$result = 
 @{
	changed = $true
	Patchstatus = "Not Determined. this could be because the job hasnt started or the job failed. Please inspect the logs APFW_Patching_dd_mm_yyyy in c:\windows\temp on the destination computer"
	Patchesremaining = "Not Determined" 
	daterun = ''
  }
$path = "$env:windir\Temp\apfw_$env:COMPUTERNAME.xml"
$testfile = Test-Path $path
if ($testfile)
{
	$xml = Import-Clixml $path
	
	if ($xml.patchesremaining -gt 0)
	{
		
		$result.changed = $true
		$result.Patchstatus = $xml.Patchingprogress
		$result.patchesremaining = $xml.patchesremaining
		$result.daterun = $xml.daterun
		Exit-Json -obj $result
		
	}elseif ($xml.patchesremaining -eq 0) #If patches remaining is equal to 0
	{	
		$result.changed = $false
		$result.Patchstatus = $xml.Patchingprogress
		$result.patchesremaining = $xml.patchesremaining
		$result.daterun = $xml.daterun
		Exit-Json -obj $result
	}elseif ($xml.PatchingProgress -eq 'failed')
	{
	
		Fail-Json $result -message  "Job Failed, Please check the logs for more info "
	}
	
	
}
else
{
	Fail-Json -obj $result -message "Not Determined. this could be because the job hasnt started or the job failed. Please inspect the logs APFW_Patching_dd_mm_yyyy in c:\windows\temp on the destination computer"
}
