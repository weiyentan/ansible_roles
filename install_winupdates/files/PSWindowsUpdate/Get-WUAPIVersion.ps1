Function Get-WUAPIVersion
{
    <#
	.SYNOPSIS
	    Show Windows Update Agent version.

	.DESCRIPTION
	    Use Get-WUAPIVersion to get Windows Update Agent version.

	.PARAMETER ComputerName	
	    Specify the name of the computer to the remote connection.

	.PARAMETER Debuger	
	    Debug mode.

	.EXAMPLE
        PS C:\> Get-WUAPIVersion
		
        WuapiDll       ApiVersion ComputerName
        --------       ---------- ------------
        10.0.14393.953 8.0        G1
		
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
					Write-Debug "Create Microsoft.Update.AgentInfo object"
					$AgentInfo = New-Object -ComObject "Microsoft.Update.AgentInfo" #Support local instance only
				} #End If $Computer -eq $env:COMPUTERNAME
				Else
				{
					Write-Debug "Create Microsoft.Update.AgentInfo object for $Computer"
					$AgentInfo =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.AgentInfo",$Computer))
				} #End Else $Computer -eq $env:COMPUTERNAME
			
                $ApiMajorVersion = $AgentInfo.GetInfo("ApiMajorVersion")
                $ApiMinorVersion = $AgentInfo.GetInfo("ApiMinorVersion")
                $WuapiDllVersion = $AgentInfo.GetInfo("ProductVersionString")

                $Result = New-Object -TypeName PSObject -Property @{
                    ApiVersion = "$($ApiMajorVersion).$($ApiMinorVersion)"
                    WuapiDll = $WuapiDllVersion
                    ComputerName = $Computer
                }

                $Results += $Result
            } # End If Test-Connection -ComputerName $Computer -Quiet         
        } # End Foreach $Computer in $ComputerName
        Return $Results

	} #End Process
	
	End{}				
} #In The End :)
