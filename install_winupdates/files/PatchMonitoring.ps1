#region Helper functions
function Remove-Patchtaskfile
{
<#
	.SYNOPSIS
		Helper function to remove items related to  patching 
	
	.DESCRIPTION
		This helper function will remove scheduled tasks , files related to the scheduled task and registry entries. It will write to a log in the windows/temp directory
	
	.EXAMPLE
				PS C:\> Remove-Patchtaskfile
	
	.NOTES
		Additional information about the function.
#>
	
	"[$(Get-Date)][$env:computername][RPT][Stop Install_Patch scheduledtask]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	schtasks /end /tn "Install_Patch"
	"[$(Get-Date)][$env:computername][RPT][Remove Install_Patch scheduledtask]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	schtasks /delete /tn "Install_Patch" /f | out-null
	"[$(Get-Date)][$env:computername][RPT][Stop Monitor_Patch scheduledtask]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	schtasks /end /tn "Monitor_Patch" /f | out-null
	"[$(Get-Date)][$env:computername][RPT][Remove Patch status file]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	"[$(Get-Date)][$env:computername][RPT][Remove Monitor_Patch scheduledtask]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	schtasks /delete /tn "Monitor_Patch" /f | out-null
	"[$(Get-Date)][$env:computername][RPT][Remove Patch Monitoring script]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	Remove-Item $env:windir\temp\Patchmonitoring.ps1 -Force
	"[$(Get-Date)][$env:computername][RPT][Remove Install Patch script]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	Remove-Item $env:windir\temp\Installpatch.ps1 -Force
	"[$(Get-Date)][$env:computername][RPT][Clean up registry settings]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	Remove-Item -Path HKLM:\SOFTWARE\APFWPatching
}
function convert-datetimetoUS ($inputdate)
{
	$InputDate = $InputDate
	$SplitDate = $InputDate.Split('/')
	$OutputDate = '{ 0 }-{ 1:D2 }-{ 2:D2 }' -f $SplitDate[2], [int]$SplitDate[1], [int]$SplitDate[0]
	write-output $OutputDate
	
}

function New-patchobj
{
<#
	.SYNOPSIS
		Creates a patchobj
	
	.DESCRIPTION
		This is a helper function that gets the patching status of the machine.
	
	.PARAMETER status
		Shows the status of the patching progress.
	
	.PARAMETER message
		A description of the message  parameter.
	
	.EXAMPLE
		PS C:\> New-patchobj
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateSet('InProgress', 'Failed', 'Success')]
		$status,
		$message,
		$ignorehidden
	)
	
	$totalcount = ((get-itemproperty HKLM:\SOFTWARE\APFWPatching -name totalpatchcount).totalpatchcount)
	if ($PSBoundParameters.ContainsKey($ignorehidden))
	{
		$patchesremaining = (get-wulist -IsNotHidden) | measure-object | select-object -expandproperty count
	}
	else
	{
		$patchesremaining = (get-wulist) | measure-object | select-object -expandproperty count
	}
	
	$patchingstatusobject = new-object -typename psobject -property @{
		computername	 = $env:COMPUTERNAME
		Patchesremaining = $patchesremaining
		PatchingProgress = $Status
		Message		     = $message
		TotalPatchCount  = $totalcount
		Rebootneeded	 = (Get-WuRebootStatus -Silent)
		Daterun		     = (Get-Date)
	}
	Write-output $patchingstatusobject
}


#endregion

$script:patchingstatus = $true
$dateformat = get-date -UFormat %d-%m-%y
$regpatchfirstrunflag = ((get-ItemProperty -Path HKLM:\SOFTWARE\APFWPatching -Name Firsttime).Firsttime)
if (!$regpatchfirstrunflag)
{
	"Patches to install" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	$totalpatches = Get-Wulist
	$totalpatchno = $totalpatches | measure-object | select-object -expandproperty count
	$totalpatches | select-object  kb, title | format-table -autosize | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	New-ItemProperty -path HKLM:\SOFTWARE\APFWPatching -name totalpatchcount -value $totalpatchno | out-null
	New-ItemProperty -Path HKLM:\SOFTWARE\APFWPatching -Name Firsttime -Value Firsttime | out-null
	
	
}

"[$env:computername][IPM][Start Monitoring Process]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append

$script:fail = $false
$script:importmoduletestfail = $false
#region populate registry details formatting in details to accomodate for US time format.
$unformatteddate = ((get-ItemProperty -Path HKLM:\SOFTWARE\APFWPatching -Name enddatetime).enddatetime)
$finalenddate = get-date $unformatteddate
[int]$waittimemin = ((get-ItemProperty -Path HKLM:\SOFTWARE\APFWPatching -Name waittime).waittime)
$ignorehidden = ((get-ItemProperty -Path HKLM:\SOFTWARE\APFWPatching -Name ignorehidden).ignorehidden)
$autoreboot = ((get-ItemProperty -Path HKLM:\SOFTWARE\APFWPatching -Name autoreboot).autoreboot)
[int]$waittimesec = $waittimemin * 60
"[$(Get-Date)][$env:computername][IPM][Endtime is $finalenddate]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
try { Import-Module PSWindowsUpdate -ErrorAction Stop }
catch
{
	$importmoduletestfail = $true
}

while ($patchingstatus -eq $true)
{
	"[$(Get-Date)][$env:computername][IPM][Entering patching loop ]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	if ($importmoduletestfail -eq $true)
	{
		New-patchobj -status Failed -message "The PSWindowsUpdate Module does not exist on this server. "
		break
	}
	"[$(Get-Date)][$env:computername][IPM][Checking if registry files are blank]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	if (!$unformatteddate)
	{
		"[$(Get-Date)][$env:computername][IPM][Registry entries for date and time is empty.]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
		break
		
	}

	$timeduration = New-TimeSpan -Start (get-date) -End (get-date $finalenddate)
	if ($Timeduration.minutes -le 0 -and $Timeduration.hours -le 0) #This is to make sure that the hours and minutes fit the consistency. Minutes could be 0 when it has 2 hours left. ie 2 hours 0 minutes
	{
		$script:fail = $true
		$patchingstatus = $false
		"[$(Get-Date)][$env:computername][IPM][Time exceeded. Failing process]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
		break
	}
	$wuinstallerstatus = Get-WUInstallerStatus -silent ## check installer status . if it is installing  then we skip the entire process below because it is unnecessary.
	"[$(Get-Date)][$env:computername][IPM][Checking Windows Update Installer status]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	
	if ($wuinstallerstatus -eq $false)
	{
		#region Creating Patch object when installer has stopped
		"[$(Get-Date)][$env:computername][IPM][Windows Installer stopped. Creating Patchobject to export to file]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
		
		if ($ignorehidden -eq 'true')
		{
			$patchingstatusobject = new-patchobj -status inprogress -ignorehidden
		}
		else
		{
			$patchingstatusobject = new-patchobj -status inprogress
			
		}
		$patchingstatusobject | export-clixml "$env:windir\temp\apfw_$env:computername.xml"
		#endregion
		"[$(Get-Date)][$env:computername][IPM][Checking reboot status of $env:computername]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
		$rebootstatus = Get-WURebootStatus -Silent
		if ($rebootstatus -eq $true)
		{
			if ($autoreboot -eq 'true')
			{
				
				"[$(Get-Date)][$env:computername][IPM][Pending Reboot. Rebooting $env:COMPUTERNAME]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
				
				Restart-Computer -Force
				
			}
			else
			{
				"[$(Get-Date)][$env:computername][IPM][There are pending reboots on $env:COMPUTERNAME but because noreboot flag chosen so server is not being rebooted.]" | out-file "`$env:windir\temp\APFW_Patching_$dateformat.log" -append
				$patchingstatus = $false
				break
				
				
			}
		}
		else
		{
			"[$(Get-Date)][$env:computername][IPM][No reboots pending.]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
			if ($ignorehidden -eq 'true')
			{
				[int]$patchesremaining = get-wulist -IsNotHidden | measure-object | select-object -expandproperty count # ---H- is a hidden status, so we are omitting it.
			}
			else
			{
				[int]$patchesremaining = get-wulist | measure-object | select-object -expandproperty count
				
			}
			"[$(Get-Date)][$env:computername][IPM][Patchesremaining: $patchesremaining]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
			
			if ($patchesremaining -eq 0)
			{
				"[$(Get-Date)][$env:computername][IPM][Patches Remaining:0]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
				$patchingstatus -eq $false
				break
			}
			else
			{
				$task = schtasks /query /TN "Install_Patch" /fo csv | convertfrom-csv
				if ($task.status -eq "Ready")
				{
					"[$(Get-Date)][$env:computername][IPM][Resume scheduled task Install_Patch as it has stopped.]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
					schtasks /run /tn "Install_Patch"
				}
				
			}
			
		}
	}
	
	if ($ignorehidden -eq 'true')
	{
		[int]$patchesremaining = get-wulist -IsNotHidden | measure-object | select-object -expandproperty count
	}
	else
	{
		[int]$patchesremaining = get-wulist | measure-object | select-object -expandproperty count
	}
	
	"[$(Get-Date)][$env:computername][IPM][Patchesremaining:$patchesremaining]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	"[$(Get-Date)][$env:computername][IPM][Wait $waittimemin minutes]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	Start-Sleep -Seconds $waittimesec
}

"[$(Get-Date)][$env:computername][IPM][out of loop. writing to log....]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append

if (!$unformatteddate)
{
	"[$(Get-Date)][$env:computername][IPM][The patching process has been halted because it has the registry entries are empty which can cause an infinite loop of patching situation]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	$patchingstatusobject = new-patchobj -status failed -message "The registry entries required for Patching is empty. Cannot continue. " | export-clixml "$env:windir\temp\apfw_$env:computername.xml" -force
	"[$(Get-Date)][$env:computername][IPM][Cleanup tasks initiated.]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	Remove-Patchtaskfile
	break
}

if ($importmoduletestfail -eq $true)
{
	"[$(Get-Date)][$env:computername][IPM][The patching process has been halted because either the PSWindowsUpdate module was not found or copied to the wrong location ]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	
	
}
if ($script:fail -eq $true) # if failed Determines what will happen by using the $script:fail scope.  
{
	schtasks /end "Monitor_Patch"
	
	"[$(Get-Date)][$env:computername][IPM][The patching process has been halted because it has exceeded the endtime of $finalenddate]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	$patchingstatusobject = new-patchobj -status failed -message "Patching did not complete within $finalenddate"
	$patchingstatusobject | export-clixml "$env:windir\temp\apfw_$env:computername.xml" -force
	"[$(Get-Date)][$env:computername][IPM][Cleanup tasks initiated.]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	Remove-Patchtaskfile
	"[$(Get-Date)][$env:computername][IPM][Cleanup tasks completed. ]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	"[$(Get-Date)][$env:computername][IPM][The following updates are not installed.]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	$remainingupdates = get-wulist | select-object -expandproperty title
	$remainingupdates | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	
}
else # if not failed. patched passed successfully
{
	"[$(Get-Date)][$env:computername][IPM][The patching process has completed successfully  within the time of $finalenddate]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	"[$(Get-Date)][$env:computername][IPM][Cleanup tasks initiated.]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	$patchingstatusobject = new-patchobj -status success -message "The computer $env:COMPUTERNAME patched successfully."
	$patchingstatusobject | export-clixml "$env:windir\temp\apfw_$env:computername.xml" -force
	Remove-Patchtaskfile
	"[$(Get-Date)][$env:computername][IPM][Cleanup tasks completed. ]" | out-file "$env:windir\temp\APFW_Patching_$dateformat.log" -append
	
}

schtasks /tn winupdate /run #run the scheduled task for updating the winupdate wsus status so can see a running realtime wsus update in thruk

