Function Start-WUService
{
    <#
	.SYNOPSIS
	    Start Windows Update components.

	.DESCRIPTION
	    Use Start-WUService to enable all components that Automatic Updates requires.

	.PARAMETER ComputerName	
	    Specify the name of the computer to the remote connection.

	.PARAMETER Debuger	
	    Debug mode.

	.EXAMPLE
        PS C:\> Start-WUService
		
	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc
	#>    

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param
    (
		#Mode options
		[Switch]$Debuger,
		[parameter(ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)]
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

        $Results = @()
        Foreach($Computer in $ComputerName)
		{        
			If(Test-Connection -ComputerName $Computer -Quiet)
			{
				If($Computer -eq $env:COMPUTERNAME)
				{
					Write-Debug "Create Microsoft.Update.AutoUpdate object"
					$AutoUpdate = New-Object -ComObject "Microsoft.Update.AutoUpdate" #Support local instance only
				} #End If $Computer -eq $env:COMPUTERNAME
				Else
				{
					Write-Debug "Create Microsoft.Update.AutoUpdate object for $Computer"
					$AutoUpdate =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.AutoUpdate",$Computer))
				} #End Else $Computer -eq $env:COMPUTERNAME
			
                $AutoUpdate.EnableService()

            } # End If Test-Connection -ComputerName $Computer -Quiet         
        } # End Foreach $Computer in $ComputerName
	} #End Process
	
	End{}				
} #In The End :)
