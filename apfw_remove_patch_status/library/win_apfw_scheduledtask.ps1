#!powershell
# This file is part of Ansible

# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.Legacy.psm1

#region helper functions
function Get-Schtask
{
<#
	.SYNOPSIS
		Test the scheduled task status
	
	.DESCRIPTION
		Gets the scheduled task status. It then outputs that as an object.
	
	.PARAMETER computername
		The is the name of the computer.
	
	.PARAMETER Credential
		A description of the Credential parameter.
	
	.PARAMETER taskname
		This is the name of the task.
	
	.PARAMETER details
		A description of the details parameter.
	
	.EXAMPLE
		PS C:\> Get-Schtask -computername
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[string[]]$computername = 'localhost',
		[System.Management.Automation.Credential()]
		$Credential = [System.Management.Automation.PSCredential]::Empty,
		[string]$taskname,
		[switch]$details
	)
	
	foreach ($computer in $computername)
	{
		try
		{
			#$ErrorActionPreference = 'Stop' #Because we are running an external command we have to force erroraction preference to stop to terminate all errors.
			
			if (!($PSBoundParameters.ContainsKey('details')))
			{
				if (!$PSBoundParameters.ContainsKey('taskname')) #if the parameter has no taskname, assume user is looking for all tasks. This code block retrieves ALL tasks on computer. 
				{
					$gettaskcsv = schtasks /query /s $computer /fo csv
				}
				else #assumes that user used task name parameter so we attach $taskname to it.
				{
					$gettaskcsv = schtasks /query /s $computer /tn $taskname /fo csv
				}
				
				
				$procobj = $gettaskcsv | Convertfrom-Csv | Where-Object { $_.taskname -ne "TaskName" -and $_.'Next Run Time' -ne "Next Run Time" -and $_.status -ne "Status" }
				foreach ($task in $procobj)
				{
					$status = $task | Select-Object -ExpandProperty status
					$taskname = $task | Select-Object -ExpandProperty taskname
					$nextruntime = $task | Select-Object -ExpandProperty 'Next Run Time'
					$hashtable = @{
						computername = $computer
						taskname	 = $taskname
						nextruntime  = $nextruntime
						status	     = $status
					}
					$object = New-Object -TypeName System.Management.Automation.PSObject -Property $hashtable
					$object.pstypenames.insert(0, 'Scheduledtask.object')
					
					Write-Output $object
				}
				
			}
			elseif (($PSBoundParameters.ContainsKey('details'))) #This is a scheduled task query if there is a detail parameter. 
			{
				if ($PSBoundParameters.ContainsKey('taskname'))
				{
					$gettaskcsv = schtasks /query /s $computer /tn $taskname /fo csv /v
				}
				else
				{
					$gettaskcsv = schtasks /query /s $computer /fo csv /v
				}
				$procobj = $gettaskcsv | Convertfrom-Csv | Where-Object { $_.taskname -ne "TaskName" -and $_.'Next Run Time' -ne "Next Run Time" -and $_.status -ne "Status" }
				foreach ($task in $procobj)
				{
					$hashtable = @{
						computername = $task.hostname
						taskname	 = $task.taskname
						nextruntime  = $task.'Next Run Time'
						status	     = $task.status
						logonmode    = $task.'Logon Mode'
						LastRunTime  = $task.'Last Run Time'
						LastResult   = $task.'Last Result'
						Author	     = $task.'Author'
						TaskToRun    = $task.'Task To Run'
						StartIn	     = $task.'Start In'
						Comment	     = $task.'Comment'
						ScheduledTaskState = $task.'Enabled'
						IdleTime	 = $task.'idle time'
						PowerManagement = $task.'Power Management'
						RunAsUser    = $task.'Run As User'
						DeletetaskIfNotRescheduled = $task.'Delete Task If Not Rescheduled'
						StopTaskIfRunsXHoursandXMins = $task.'Stop Task If Runs X Hours and X Mins'
						Schedule	 = $task.Schedule
						ScheduleType = $task.'Schedule Type'
						StartTime    = $task.'Start Time'
						Startdate    = $task.'Start date'
						Enddate	     = $task.'End Date'
						Days		 = $task.Days
						Months	     = $task.months
						RepeatEvery  = $task.'Repeat: Every'
						Repeatuntiltime = $task.'Repeat: Every'
						RepeatUntilDuration = $task.'Repeat: Until: Duration'
						RepeatStopIfStillRunning = $task.'Repeat: Stop If Still Running'
					}
					$object = New-Object -TypeName System.Management.Automation.PSObject -Property $hashtable
					$object.pstypenames.insert(0, 'Scheduledtask.Detailed.object')
					
					Write-Output $object
				}
				
			}
			
			
		}
		catch
		{
			##WYT : Revision would like to Test-Port by SN . ok to use to check for additional smarts?
			Write-Error -Message "Unable to find Scheduled task $taskname on computer $computer"
			break
		}
		
		finally
		{
			$ErrorActionPreference = 'Continue' #Turn on Erroraction preference back to original status
		}
		
	}
}
#endregion 
$params = Parse-Args -arguments $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false
$diff_mode = Get-AnsibleParam -obj $params -name "_ansible_diff" -type "bool" -default $false

# these are your module parameters, there are various types which can be
# used to format your parameters. You can also set mandatory parameters
# with -failifempty, set defaults with -default and set choices with
# -validateset.
$name = Get-AnsibleParam -obj $params -name "name" -type "str" -failifempty $true -validateset "Monitor_Patch", "Install_Patch"
$state = Get-AnsibleParam -obj $params -name "state" -type "str" -default "present" -validateset "absent", "present"
$autoreboot = Get-AnsibleParam -obj $params -name "autoreboot" -type "str" -default "false" -validateset "true", "false"
$result = @{
	changed = $false
	msg = 'Nothing changed'
}

if ($diff_mode)
{
	$result.diff = @{ }
}
$evaltask = Get-Schtask -computername $env:COMPUTERNAME -taskname $name

if ($name -eq "Install_Patch")
{
	if ($state -eq 'present')
	{
		if (!$evaltask)
		{
			if (-not ($check_mode))
			{
				if ($autoreboot -eq 'false'){
				SCHTASKS /Create   /RU system /SC ONEVENT /EC System /MO *[System/EventID=101]  /TN Install_Patch /f /RL highest  /TR  "powershell.exe  -executionpolicy bypass -Command ipmo PSWindowsUpdate; Get-WUInstall -AcceptAll "
				}elseif ($autoreboot -eq 'true') {
					SCHTASKS /Create   /RU system /SC ONEVENT /EC System /MO *[System/EventID=101]  /TN Install_Patch /f /RL highest  /TR  "powershell.exe  -executionpolicy bypass -Command ipmo PSWindowsUpdate; Get-WUInstall -AcceptAll -Autoreboot "

				}
			}
			$result.changed = $true
			$result.msg = "Schedule task Install_Patch was created"
		}
		else
		{
			$result.msg = "The Schedule task Install_Patch is already present "
		}
		
	}
	elseif ($state -eq 'absent')
	{
		if ($evaltask)
		{
			if (-not $checkmode)
			{
				schtasks /delete /tn "Install_Patch" /f
			}
			$result.changed = $true
			$result.msg = " The Schedule task Install_Patch has been removed"
			
		}
		else
		{
			$result.msg = "The Schedule task Install_Patch is already removed"
		}
		
	}
	
}

if ($name -eq "Monitor_Patch")
{
	if ($state -eq 'present')
	{
		if (!$evaltask)
		{
			if (-not ($check_mode))
			{
				SCHTASKS /Create  /RU system /SC  onstart /delay 0005:00 /TN Monitor_Patch /f /RL highest  /TR  "powershell.exe -executionpolicy bypass -file $env:windir\temp\Patchmonitoring.ps1"
			}
			$result.changed = $true
			$result.msg = "The Schedule task Monitor_Patch was created"
		}
		else
		{
			$result.msg = "The Schedule task Monitor_Patch is already present"
		}
	}
	if ($state -eq 'absent')
	{
		if ($evaltask)
		{
			if (-not ($check_mode))
			{
				schtasks /delete /tn "Monitor_Patch" /f 
			}
			$result.changed = $true
			
		}
		else
		{
			$result.msg = "The Schedule task Monitor_Patch is already removed"
		}
		
	}
}

Exit-Json -obj $result

# Reference
# https://docs.ansible.com/ansible/2.6/dev_guide/developing_modules_general_windows.html
# https://docs.ansible.com/ansible/2.4/dev_guide/developing_modules_general_windows.html