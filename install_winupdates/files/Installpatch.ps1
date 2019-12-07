import-module PSWindowsUpdate
	function New-patchobj
	{
	<#
		.SYNOPSIS
			Creates a patchobj
		
		.DESCRIPTION
			This is a helper function that gets the patching status of the computer.
		
		.PARAMETER status
			Shows the status of the patching progress. 
		
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
	        [switch]$ignorehidden
		)
		if($PSBoundParameter.containskey('ignorehidden')){
	      $patchesremaining = get-wulist -isnothidden | measure-object | select-object -expandproperty count
	    }else{
			$patchesremaining = (get-wulist) | measure-object | select-object -expandproperty count
	    }
		import-module PSWindowsUpdate
	    $totalcount = ((get-itemproperty HKLM:\SOFTWARE\APFWPatching -name totalpatchcount).totalpatchcount)
		$patchingstatusobject = new-object -typename psobject -property @{
			computername	 = $env:COMPUTERNAME
			Patchesremaining = $patchesremaining
			PatchingProgress = $Status
			Message          = $message
	        TotalPatchCount  =  $totalcount
	        Rebootneeded     = (Get-WuRebootStatus -Silent)
			Daterun          = (Get-date)
		}
		Write-output $patchingstatusobject
	}
	
	$patchingstatusobject = new-patchobj -status inprogress
    $patchingstatusobject | export-clixml "$env:windir\temp\apfw_$env:computername.xml" -force 
     
	 Get-WUInstall -AcceptAll 