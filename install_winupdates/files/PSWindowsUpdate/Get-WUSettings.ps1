Function Get-WUSettings
{
    <#
	.SYNOPSIS
	    Get Windows Update settings.

	.DESCRIPTION
	    Use Get-WUSettings to get Windows Update settings.

	.PARAMETER WUAAPI
        Use Windows Update Agent API. Works only on local machine.

	.PARAMETER Registry
        Use Windows registry. Works only for GPO settings.

	.PARAMETER ComputerName	
	    Specify the name of the computer to the remote connection.

	.PARAMETER Debuger	
	    Debug mode.

	.EXAMPLE
        PS C:\> Get-WUSettings -Registry
		
            AcceptTrustedPublisherCerts   : 1
            WUServer                      : https://wsus.contoso.com
            WUStatusServer                : https://wsus.contoso.com
            DetectionFrequencyEnabled     : 1
            DetectionFrequency            : 2
            NoAutoRebootWithLoggedOnUsers : 1
            RebootRelaunchTimeoutEnabled  : 1
            RebootRelaunchTimeout         : 240
            IncludeRecommendedUpdates     : 0
            NoAutoUpdate                  : 0
            AUOptions                     : 2 - Notify before download
            ScheduledInstallDay           : 0 - Every Day
            ScheduledInstallTime          : 4
            UseWUServer                   : 1
            ComputerName                  : G1
		
	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc
	#>    

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low",
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
		[parameter(ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
            ParameterSetName='Registry')]
		[String[]]$ComputerName    
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

        $NotificationLevels = @{ 0="0 - Not configured"; 1="1 - Disabled"; 2="2 - Notify before download"; 3="3 - Notify before installation"; 4="4 - Scheduled installation"; 5="5 - Users configure" }
        $ScheduledInstallationDays = @{ 0="0 - Every Day"; 1="1 - Every Sunday"; 2="2 - Every Monday"; 3="3 - Every Tuesday"; 4="4 - Every Wednesday"; 5="5 - Every Thursday"; 6="6 - Every Friday"; 7="7 - EverySaturday" }

        $Results = @()
        Foreach($Computer in $ComputerName)
		{        
		    If(Test-Connection -ComputerName $Computer -Quiet)
			{
                Write-Debug "Connect to reg HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate for $Computer"
				$RegistryKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine",$Computer) 
                $RegistrySubKey1 = $RegistryKey.OpenSubKey("SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\") 
                $RegistrySubKey2 = $RegistryKey.OpenSubKey("SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\")                
                
                if($RegistrySubKey1) { Write-Verbose "Some settings are managed by your system administrator." }
                                
                if($WUAAPI)
                {
                    $AutoUpdateSettings = (New-Object -ComObject Microsoft.Update.AutoUpdate).Settings

                    $Result = New-Object -TypeName PSObject -Property @{
                        NotificationLevel = $NotificationLevels[$AutoUpdateSettings.NotificationLevel]
                        ScheduledInstallationDay = $ScheduledInstallationDays[$AutoUpdateSettings.ScheduledInstallationDay]
                        ScheduledInstallationTime = $AutoUpdateSettings.ScheduledInstallationTime
                        IncludeRecommendedUpdates = $AutoUpdateSettings.IncludeRecommendedUpdates
                        NonAdministratorsElevated = $AutoUpdateSettings.NonAdministratorsElevated
                        FeaturedUpdatesEnabled = $AutoUpdateSettings.FeaturedUpdatesEnabled
                    }
                } elseif($Registry)
                {
				    $Result = New-Object -TypeName PSObject
                    Try
                    {
                        Foreach($RegName in $RegistrySubKey1.GetValueNames()) 
                        { 
                            $Value = $RegistrySubKey1.GetValue($RegName) 
                            $Result | Add-Member -MemberType NoteProperty -Name $RegName -Value $Value
                        }
                        Foreach($RegName in $RegistrySubKey2.GetValueNames()) 
                        { 
                            $Value = $RegistrySubKey2.GetValue($RegName) 
                            Switch($RegName)
                            {
                                'AUOptions' { $Value = $NotificationLevels[$Value] }
                                'ScheduledInstallDay' { $Value = $ScheduledInstallationDays[$Value] }
                            }
                            $Result | Add-Member -MemberType NoteProperty -Name $RegName -Value $Value
                        }
			        }
                    Catch
                    {
                        Write-Error "Can't find registry subkey: HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate. Probably you don't use Group Policy for Windows Update settings. Try use -WUAAPI on local machine." -ErrorAction Stop
                    }

                    $Result | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $Computer
                } #End elseif $Registry
                $Results += $Result
            } # End If Test-Connection -ComputerName $Computer -Quiet         
        } # End Foreach $Computer in $ComputerName
 
        Return $Results

	} #End Process
	
	End{}				
} #In The End :)
