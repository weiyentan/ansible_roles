Function Set-WUSettings
{
    <#
	.SYNOPSIS
	    Set Windows Update settings.

	.DESCRIPTION
	    Use Set-WUSettings to set Windows Update settings.

	.PARAMETER WUAAPI
        Use Windows Update Agent API. Works only on local machine.

	.PARAMETER Registry
        Use Windows registry.

	.PARAMETER IncludeRecommendedUpdates

	.PARAMETER AcceptTrustedPublisherCerts
		Enabled - The WSUS server distributes available signed non-Microsoft updates.
		Disabled - The WSUS server does not distribute available signed non-Microsoft updates.

	.PARAMETER DisableWindowsUpdateAccess
		Disables/Enables access to Windows Update.
		
	.PARAMETER NonAdministratorsElevated
		Enabled - All members of the Users security group can approve or disapprove updates.
		Disabled - Only members of the Administrators security group can approve or disapprove updates.
		
	.PARAMETER TargetGroup
		Name of the computer group to which the computer belongs. 
		
	.PARAMETER TargetGroupEnabled
		Use/Do not use client-side targeting.
		
	.PARAMETER WSUSServer
		HTTP(S) URL of the WSUS server that is used by Automatic Updates and API callers (by default). 

	.PARAMETER NotificationLevel
		Notify mode: "Not configured", "Disabled", "Notify before download", "Notify before installation", "Scheduled installation", "Users configure"

	.PARAMETER AutoInstallMinorUpdates
		Silently install minor updates.
		
	.PARAMETER DetectionFrequency
		Time between detection cycles. Time in hours (1–22).
		
	.PARAMETER DetectionFrequencyEnabled
		Enable/Disable detection frequency.
		
	.PARAMETER NoAutoRebootWithLoggedOnUsers
		Logged-on user can decide whether to restart the client computer.
		
	.PARAMETER NoAutoUpdate
		Enable/Disable Automatic Updates.
		
	.PARAMETER RebootRelaunchTimeout
		Time between prompts for a scheduled restart. Time in minutes (1–1440).
		
	.PARAMETER RebootRelaunchTimeoutEnabled
		Enable/Disable RebootRelaunchTimeout.
		
	.PARAMETER RebootWarningTimeout
		Length, in minutes, of the restart warning countdown after updates have been installed that have a deadline or scheduled updates. Time in minutes (1–30).
		
	.PARAMETER RebootWarningTimeoutEnabled
		Enable/Disable RebootWarningTimeout.
		
	.PARAMETER RescheduleWaitTime
		Time in minutes that Automatic Updates waits at startup before it applies updates from a missed scheduled installation time. Time in minutes (1–60).
		
	.PARAMETER ScheduledInstallDay
		Scheduled day of install: "Every day", "Every Sunday", "Every Monday", "Every Tuesday", "Every Wednesday", "Every Thursday", ""Every Friday", "EverySaturday". Only valid if NotificationLevel (AUOptions) = "Scheduled installation"		
		Starting with Windows 8 and Windows Server 2012, ScheduledInstallationDay are not supported and will return unreliable values. If you try to modify these properties, the operation will appear to succeed but will have no effect.
		
	.PARAMETER ScheduledInstallTime
		Scheduled time of install in 24-hour format (0–23).
		Starting with Windows 8 and Windows Server 2012, ScheduledInstallTime are not supported and will return unreliable values. If you try to modify these properties, the operation will appear to succeed but will have no effect.
		
	.PARAMETER UseWUServer
		The computer gets its updates from a WSUS server or from Microsoft Update.

	.PARAMETER ComputerName	
	    Specify the name of the computer to the remote connection.

	.PARAMETER Debuger	
	    Debug mode.

	.EXAMPLE
        PS C:\> Set-WUSettings -Registry -AUOptions "Notify before download" -WSUSServer "https://wsus.contoso.com" -UseWUServer -Verbose
		
        ComputerName WUServer                 AUOptions UseWUServer
        ------------ --------                 --------- -----------
        G1           https://wsus.contoso.com         2           1
		
	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc
	#>    

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="High",
        DefaultParameterSetName="Registry"
    )]
    Param
    (
		#Mode options
		[Switch]$Debuger,
        [Parameter(ParameterSetName='WUAAPI')]
        [Switch]$WUAAPI,
        [Parameter(ParameterSetName='Registry')]
        [Switch]$Registry = $True,
		[Parameter(ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
            ParameterSetName='Registry')]
		[String[]]$ComputerName,

        [Switch]$IncludeRecommendedUpdates,
        
        [Parameter(ParameterSetName='Registry')]
        [Switch]$AcceptTrustedPublisherCerts,
        [Parameter(ParameterSetName='Registry')]
        [Switch]$DisableWindowsUpdateAccess,
        [Alias('ElevateNonAdmins')]
        [Switch]$NonAdministratorsElevated,
        [Parameter(ParameterSetName='Registry')]
        [String]$TargetGroup,
        [Parameter(ParameterSetName='Registry')]
        [Switch]$TargetGroupEnabled,
        [Parameter(ParameterSetName='Registry')]
        [String]$WUServer,

        [ValidateSet("Not configured","Disabled","Notify before download","Notify before installation","Scheduled installation","Users configure")]
        [Alias('AUOptions')]
        [String]$NotificationLevel,
        [Parameter(ParameterSetName='Registry')]
        [Switch]$AutoInstallMinorUpdates,
        [Parameter(ParameterSetName='Registry')]
        [ValidateRange(1,22)]
        [Int]$DetectionFrequency,
        [Parameter(ParameterSetName='Registry')]
        [Switch]$DetectionFrequencyEnabled,
        [Parameter(ParameterSetName='Registry')]
        [Switch]$NoAutoRebootWithLoggedOnUsers,
        [Parameter(ParameterSetName='Registry')]
        [Switch]$NoAutoUpdate,
        [Parameter(ParameterSetName='Registry')]
        [ValidateRange(1,1440)]
        [Int]$RebootRelaunchTimeout,
        [Parameter(ParameterSetName='Registry')]
        [Switch]$RebootRelaunchTimeoutEnabled,
        [Parameter(ParameterSetName='Registry')]
        [ValidateRange(1,30)]
        [Int]$RebootWarningTimeout,
        [Parameter(ParameterSetName='Registry')]
        [Switch]$RebootWarningTimeoutEnabled,
        [Parameter(ParameterSetName='Registry')]
        [ValidateRange(1,60)]
        [Int]$RescheduleWaitTime,
        [ValidateSet("Every Day","Every Sunday","Every Monday","Every Tuesday","Every Wednesday","Every Thursday","Every Friday","EverySaturday")]
        [String]$ScheduledInstallDay,
        [ValidateRange(0,23)]
        [Int]$ScheduledInstallTime,
        [Parameter(ParameterSetName='Registry')]
        [Switch]$UseWUServer
    )
	
	Begin
	{
		If($PSBoundParameters['Debuger'])
		{
			$DebugPreference = "Continue"
		} #End If $PSBoundParameters['Debuger']
		
		$User = [Security.Principal.WindowsIdentity]::GetCurrent()
		$Role = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

		if(!$Role)
		{
			Write-Warning "To perform some operations you must run an elevated Windows PowerShell console."	
		} #End If !$Role		
	}
	
	Process
	{
        Write-Debug "Check if ComputerName in set"
		If($ComputerName -eq $null)
		{
			Write-Debug "Set ComputerName to localhost"
			[String[]]$ComputerName = $env:COMPUTERNAME
		} #End If $ComputerName -eq $null

        $NotificationLevels = @{ "Not configured"=0; "Disabled"=1; "Notify before download"=2; "Notify before installation"=3; "Scheduled installation"=4; "Users configure"=5 }
        $ScheduledInstallationDays = @{ "Every Day"=0; "Every Sunday"=1; "Every Monday"=2; "Every Tuesday"=3; "Every Wednesday"=4; "Every Thursday"=5; "Every Friday"=6; "EverySaturday"=7 }

        $Results = @()
        Foreach($Computer in $ComputerName)
		{        
		    Write-Verbose "Connecting to $Computer"
            If(Test-Connection -ComputerName $Computer -Quiet)
			{
                Write-Debug "Connect to reg HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate for $Computer"
				$RegistryKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine",$Computer) 
                $RegistrySubKey1 = $RegistryKey.OpenSubKey("SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\") 
                $RegistrySubKey2 = $RegistryKey.OpenSubKey("SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\")                
                
                $Result = New-Object -TypeName PSObject -Property @{ComputerName = $Computer}
                if($RegistrySubKey1) { Write-Warning "Some settings are managed by your system administrator. Changes may don't be applied." }

                if($WUAAPI)
                {
                    $AutoUpdateSettings = (New-Object -ComObject Microsoft.Update.AutoUpdate).Settings
                    
                    if($IncludeRecommendedUpdates -and $AutoUpdateSettings.IncludeRecommendedUpdates -ne $IncludeRecommendedUpdates) 
                    { 
                        $Result | Add-Member -MemberType NoteProperty -Name "IncludeRecommendedUpdates" -Value $IncludeRecommendedUpdates
                        Write-Verbose "$Computer IncludeRecommendedUpdates: $($AutoUpdateSettings.IncludeRecommendedUpdates) => $IncludeRecommendedUpdates"
                        $AutoUpdateSettings.IncludeRecommendedUpdates = $IncludeRecommendedUpdates 
                    }
                    if($NonAdministratorsElevated -and $AutoUpdateSettings.NonAdministratorsElevated -ne $NonAdministratorsElevated) 
                    { 
                        $Result | Add-Member -MemberType NoteProperty -Name "NonAdministratorsElevated" -Value $NonAdministratorsElevated
                        Write-Verbose "$Computer NonAdministratorsElevated: $($AutoUpdateSettings.NonAdministratorsElevated) => $NonAdministratorsElevated"
                        $AutoUpdateSettings.NonAdministratorsElevated = $NonAdministratorsElevated 
                    }
                    if($NotificationLevel -and $AutoUpdateSettings.NotificationLevel -ne $NotificationLevels[$NotificationLevel] ) 
                    { 
                        $Result | Add-Member -MemberType NoteProperty -Name "NotificationLevel" -Value $($NotificationLevels[$NotificationLevel])
                        Write-Verbose "$Computer NotificationLevel: $($AutoUpdateSettings.NotificationLevel) => $($NotificationLevels[$NotificationLevel])"
                        $AutoUpdateSettings.NotificationLevel = $NotificationLevels[$NotificationLevel] 
                    }
                    if($ScheduledInstallDay -and $AutoUpdateSettings.ScheduledInstallationDay -ne $ScheduledInstallationDays[$ScheduledInstallDay]) 
                    { 
                        $Result | Add-Member -MemberType NoteProperty -Name "ScheduledInstallationDay" -Value $($ScheduledInstallationDays[$ScheduledInstallDay])
                        Write-Verbose "$Computer ScheduledInstallationDay: $($AutoUpdateSettings.ScheduledInstallationDay) => $($ScheduledInstallationDays[$ScheduledInstallDay])"
                        Write-Warning "Starting with Windows 8 and Windows Server 2012, ScheduledInstallationTime are not supported and will return unreliable values. If you try to modify these properties, the operation will appear to succeed but will have no effect."
                        $AutoUpdateSettings.ScheduledInstallationDay = $ScheduledInstallationDays[$ScheduledInstallDay] 
                    }
                    if($ScheduledInstallTime -and $AutoUpdateSettings.ScheduledInstallTime -ne $ScheduledInstallTime) 
                    { 
                        $Result | Add-Member -MemberType NoteProperty -Name "ScheduledInstallTime" -Value $ScheduledInstallTime
                        Write-Verbose "$Computer ScheduledInstallationDay: $($AutoUpdateSettings.ScheduledInstallTime) => $ScheduledInstallTime"
                        Write-Warning "Starting with Windows 8 and Windows Server 2012, ScheduledInstallationTime are not supported and will return unreliable values. If you try to modify these properties, the operation will appear to succeed but will have no effect."
                        $AutoUpdateSettings.ScheduledInstallTime = $ScheduledInstallTime 
                    }

                    $AutoUpdateSettings.Save()

                } elseif($Registry)
                {
                    if(!$RegistrySubKey1) { $RegistrySubKey1 = $RegistryKey.CreateSubKey("SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\") }
                    if(!$RegistrySubKey2) { $RegistrySubKey2 = $RegistryKey.CreateSubKey("SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\") }

                    $RegistrySubKey1 = $RegistryKey.OpenSubKey("SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\",$True) 
                    $RegistrySubKey2 = $RegistryKey.OpenSubKey("SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\",$True) 

                    if($AcceptTrustedPublisherCerts) 
                    { 
                        $NewReg = [Int]$AcceptTrustedPublisherCerts.ToBool()
                        $OldReg = $RegistrySubKey1.GetValue("AcceptTrustedPublisherCerts")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "AcceptTrustedPublisherCerts" -Value $NewReg
                            Write-Verbose "$Computer AcceptTrustedPublisherCerts: $OldReg => $NewReg"
                            $RegistrySubKey1.SetValue("AcceptTrustedPublisherCerts", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($DisableWindowsUpdateAccess) 
                    { 
                        $NewReg = [Int]$DisableWindowsUpdateAccess.ToBool()
                        $OldReg = $RegistrySubKey1.GetValue("DisableWindowsUpdateAccess")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "DisableWindowsUpdateAccess" -Value $NewReg
                            Write-Verbose "$Computer DisableWindowsUpdateAccess: $OldReg => $NewReg"
                            $RegistrySubKey1.SetValue("DisableWindowsUpdateAccess", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($NonAdministratorsElevated) 
                    { 
                        $NewReg = [Int]$NonAdministratorsElevated.ToBool()
                        $OldReg = $RegistrySubKey1.GetValue("ElevateNonAdmins")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "ElevateNonAdmins" -Value $NewReg
                            Write-Verbose "$Computer ElevateNonAdmins: $OldReg => $NewReg"
                            $RegistrySubKey1.SetValue("ElevateNonAdmins", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    }
                    if($TargetGroup) 
                    { 
                        $NewReg = $TargetGroup
                        $OldReg = $RegistrySubKey1.GetValue("TargetGroup")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "TargetGroup" -Value $NewReg
                            Write-Verbose "$Computer TargetGroup: $OldReg => $NewReg"
                            $RegistrySubKey1.SetValue("TargetGroup", $NewReg, [Microsoft.Win32.RegistryValueKind]::String)
                        }
                    }
                    if($TargetGroupEnabled) 
                    { 
                        $NewReg = [Int]$TargetGroupEnabled.ToBool()
                        $OldReg = $RegistrySubKey1.GetValue("TargetGroupEnabled")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "TargetGroupEnabled" -Value $NewReg
                            Write-Verbose "$Computer TargetGroupEnabled: $OldReg => $NewReg"
                            $RegistrySubKey1.SetValue("TargetGroupEnabled", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    }
                    if($WUServer) 
                    { 
                        $NewReg = $WUServer
                        $OldReg = $RegistrySubKey1.GetValue("WUServer")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "WUServer" -Value $NewReg
                            Write-Verbose "$Computer WUServer: $OldReg => $NewReg"
                            $RegistrySubKey1.SetValue("WUServer", $NewReg, [Microsoft.Win32.RegistryValueKind]::String)
                            $RegistrySubKey1.SetValue("WUStatusServer", $NewReg, [Microsoft.Win32.RegistryValueKind]::String)
                        }
                    }


                    if($NotificationLevel) 
                    { 
                        $NewReg = [Int]$NotificationLevels[$NotificationLevel]
                        $OldReg = $RegistrySubKey2.GetValue("AUOptions")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "AUOptions" -Value $NewReg
                            Write-Verbose "$Computer AUOptions: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("AUOptions", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($AutoInstallMinorUpdates) 
                    { 
                        $NewReg = [Int]$AutoInstallMinorUpdates.ToBool()
                        $OldReg = $RegistrySubKey2.GetValue("AutoInstallMinorUpdates")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "AutoInstallMinorUpdates" -Value $NewReg
                            Write-Verbose "$Computer AutoInstallMinorUpdates: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("AutoInstallMinorUpdates", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($DetectionFrequency) 
                    { 
                        $NewReg = [Int]$DetectionFrequency
                        $OldReg = $RegistrySubKey2.GetValue("DetectionFrequency")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "DetectionFrequency" -Value $NewReg
                            Write-Verbose "$Computer DetectionFrequency: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("DetectionFrequency", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($DetectionFrequencyEnabled) 
                    { 
                        $NewReg = [Int]$DetectionFrequencyEnabled.ToBool()
                        $OldReg = $RegistrySubKey2.GetValue("DetectionFrequencyEnabled")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "DetectionFrequencyEnabled" -Value $NewReg
                            Write-Verbose "$Computer DetectionFrequencyEnabled: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("DetectionFrequencyEnabled", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($IncludeRecommendedUpdates) 
                    { 
                        $NewReg = [Int]$IncludeRecommendedUpdates.ToBool()
                        $OldReg = $RegistrySubKey2.GetValue("IncludeRecommendedUpdates")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "IncludeRecommendedUpdates" -Value $NewReg
                            Write-Verbose "$Computer IncludeRecommendedUpdates: $OldReg => $NewReg"                     
                            $RegistrySubKey2.SetValue("IncludeRecommendedUpdates", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($NoAutoRebootWithLoggedOnUsers) 
                    { 
                        $NewReg = [Int]$NoAutoRebootWithLoggedOnUsers.ToBool()
                        $OldReg = $RegistrySubKey2.GetValue("NoAutoRebootWithLoggedOnUsers")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "NoAutoRebootWithLoggedOnUsers" -Value $NewReg
                            Write-Verbose "$Computer NoAutoRebootWithLoggedOnUsers: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("NoAutoRebootWithLoggedOnUsers", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($NoAutoUpdate) 
                    { 
                        $NewReg = [Int]$NoAutoUpdate.ToBool()
                        $OldReg = $RegistrySubKey2.GetValue("NoAutoUpdate")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "NoAutoUpdate" -Value $NewReg
                            Write-Verbose "$Computer NoAutoUpdate: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("NoAutoUpdate", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($RebootRelaunchTimeout) 
                    { 
                        $NewReg = [Int]$RebootRelaunchTimeout
                        $OldReg = $RegistrySubKey2.GetValue("RebootRelaunchTimeout")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "RebootRelaunchTimeout" -Value $NewReg
                            Write-Verbose "$Computer RebootRelaunchTimeout: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("RebootRelaunchTimeout", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($RebootRelaunchTimeoutEnabled) 
                    { 
                        $NewReg = [Int]$RebootRelaunchTimeoutEnabled.ToBool()
                        $OldReg = $RegistrySubKey2.GetValue("RebootRelaunchTimeoutEnabled")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "RebootRelaunchTimeoutEnabled" -Value $NewReg
                            Write-Verbose "$Computer RebootRelaunchTimeoutEnabled: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("RebootRelaunchTimeoutEnabled", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                       }
                    }
                    if($RebootWarningTimeout) 
                    { 
                        $NewReg = [Int]$RebootWarningTimeout
                        $OldReg = $RegistrySubKey2.GetValue("RebootWarningTimeout")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "RebootWarningTimeout" -Value $NewReg
                            Write-Verbose "$Computer RebootWarningTimeout: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("RebootWarningTimeout", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($RebootWarningTimeoutEnabled) 
                    { 
                        $NewReg = [Int]$RebootWarningTimeoutEnabled.ToBool()
                        $OldReg = $RegistrySubKey2.GetValue("RebootWarningTimeoutEnabled")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "RebootWarningTimeoutEnabled" -Value $NewReg
                            Write-Verbose "$Computer RebootWarningTimeoutEnabled: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("RebootWarningTimeoutEnabled", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                       }
                    }
                    if($RescheduleWaitTime) 
                    { 
                        $NewReg = [Int]$RescheduleWaitTime
                        $OldReg = $RegistrySubKey2.GetValue("RescheduleWaitTime")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "RescheduleWaitTime" -Value $NewReg
                            Write-Verbose "$Computer RescheduleWaitTime: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("RescheduleWaitTime", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($ScheduledInstallDay) 
                    { 
                        $NewReg = [Int]$ScheduledInstallationDays[$ScheduledInstallDay]
                        $OldReg = $RegistrySubKey2.GetValue("ScheduledInstallDay")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "ScheduledInstallDay" -Value $NewReg
                            Write-Verbose "$Computer ScheduledInstallDay: $OldReg => $NewReg"
                            Write-Warning "Starting with Windows 8 and Windows Server 2012, ScheduledInstallationDay are not supported and will return unreliable values. If you try to modify these properties, the operation will appear to succeed but will have no effect."
                            $RegistrySubKey2.SetValue("ScheduledInstallDay", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord)
                        } 
                    }
                    if($ScheduledInstallTime) 
                    { 
                        $NewReg = [Int]$ScheduledInstallTime
                        $OldReg = $RegistrySubKey2.GetValue("ScheduledInstallTime")
                        if($NewReg -ne $OldReg)
                        {                        
                            $Result | Add-Member -MemberType NoteProperty -Name "ScheduledInstallTime" -Value $NewReg
                            Write-Verbose "$Computer ScheduledInstallTime: $OldReg => $NewReg"
                            Write-Warning "Starting with Windows 8 and Windows Server 2012, ScheduledInstallationTime are not supported and will return unreliable values. If you try to modify these properties, the operation will appear to succeed but will have no effect."
                            $RegistrySubKey2.SetValue("ScheduledInstallTime", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                    if($UseWUServer) 
                    { 
                        $NewReg = [Int]$UseWUServer.ToBool()
                        $OldReg = $RegistrySubKey2.GetValue("UseWUServer")
                        if($NewReg -ne $OldReg)
                        {
                            $Result | Add-Member -MemberType NoteProperty -Name "UseWUServer" -Value $NewReg
                            Write-Verbose "$Computer UseWUServer: $OldReg => $NewReg"
                            $RegistrySubKey2.SetValue("UseWUServer", $NewReg, [Microsoft.Win32.RegistryValueKind]::DWord) 
                        }
                    }
                }
                
                $Results += $Result    
            } # End If Test-Connection -ComputerName $Computer -Quiet         
        } # End Foreach $Computer in $ComputerName
	
        Return $Results
    } #End Process
	
	End{}				
} #In The End :)
