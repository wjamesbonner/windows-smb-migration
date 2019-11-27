param (
[string] $source = "",
[string] $sourceUsername = "",
[string] $sourcePasswordInput = "",
[switch] $sourceNetUse = $true,
[string] $destination = "",
[string] $destinationUsername = "",
[string] $destinationPasswordInput = "",
[switch] $destinationNetUse = $true,
[switch] $destructive = $false,
[switch] $multithreaded = $true
)

if ($source -eq "") {
	$source = Read-Host "Enter the source server (\\server)"
}

if ($sourceUsername -eq "") {
	$sourceUsername = Read-Host "Enter the source username (host\username)"
}

if ($sourcePasswordInput -ne "") {
	$sourcePassword = ConvertTo-SecureString -String $sourcePasswordInput -AsPlainText -force
	$sourcePasswordInput = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
} else {
	$sourcePassword = Read-Host -assecurestring "Please enter the source password"
}

if ($destination -eq "") {
	$destination = Read-Host "Enter the destination server (\\server)"
}

if ($destinationUsername -eq "") {
	$destinationUsername = Read-Host "Enter the destination username (host\username)"
}

if ($destinationPasswordInput -ne "") {
	$destinationPassword = ConvertTo-SecureString -String $destinationPasswordInput -AsPlainText -force
	$destinationPasswordInput = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
} else {
	$destinationPassword = Read-Host -assecurestring "Please enter the destination password"
}

$shares = (net view $source)
$shares = $shares[7..($shares.length - 3)]

if ($multithreaded -eq $true) {
	$running_jobs = @()
	
	$shares | foreach-object {
		$share = $_
		$from = $source + $share.split(' ')[0]
		$to = $destination + $share.split(' ')[0]
		
		$job = start-job -ScriptBlock {
			param ($from, $to, $sourceUsername, $sourcePassword, $destinationUsername, $destinationPassword, $sourceNetUse, $destinationNetUse, $destructive)
			
			if($sourceNetUse -eq $true) {
				NET USE $from /u:$sourceUsername $([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sourcePassword)))
			}
			
			if($destinationNetUse -eq $true) {
				NET USE $to /u:$destinationUsername $([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($destinationPassword)))
			}
			
			if ($destructive -eq $true) {
				# Do a destructive mirroring from source to destination
				robocopy $from $to /E /MIR /SEC /FFT /R:3 /W:10 /MT:10 /Z /NP /NDL /XD `#* /XF "$to\#MigrationStatus.txt" /LOG:"$to\#MigrationStatus.txt" 
			} else {
				# Do a non-destructive copy from source to destination
				robocopy $from $to /E /XO /SEC /FFT /R:3 /W:10 /MT:10 /Z /NP /NDL /XD `#* /XF "$to\#MigrationStatus.txt" /LOG:"$to\#MigrationStatus.txt" 
			}
					
			if($sourceNetUse -eq $true) {
				NET USE $from /D
			}
			
			if($destinationNetUse -eq $true) {
				NET USE $to /D
			}
		
		} -Name $source -ArgumentList $from, $to, $sourceUsername, $sourcePassword, $destinationUsername, $destinationPassword, $sourceNetUse, $destinationNetUse, $destructive
		
		$running_jobs += $job
	}
	
	foreach ($j in $running_jobs) 
	{
		Wait-Job $j
		$r = Receive-Job $j
	}
} else {
	$shares | foreach-object {
		$share = $_
		$from = $source + $share.split(' ')[0]
		$to = $destination + $share.split(' ')[0]
		
		if($sourceNetUse -eq $true) {
			NET USE $from /u:$sourceUsername $([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sourcePassword)))
		}
		
		if($destinationNetUse -eq $true) {
			NET USE $to /u:$destinationUsername $([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($destinationPassword)))
		}
		
		if ($destructive -eq $true) {
			# Do a destructive mirroring from source to destination
			robocopy $from $to /E /MIR /SEC /FFT /R:3 /W:10 /MT:10 /Z /NP /NDL /XD `#* /XF "$to\#MigrationStatus.txt" /LOG:"$to\#MigrationStatus.txt" 
		} else {
			# Do a non-destructive copy from source to destination
			robocopy $from $to /E /XO /SEC /FFT /R:3 /W:10 /MT:10 /Z /NP /NDL /XD `#* /XF "$to\#MigrationStatus.txt" /LOG:"$to\#MigrationStatus.txt" 
		}
				
		if($sourceNetUse -eq $true) {
			NET USE $from /D
		}
		
		if($destinationNetUse -eq $true) {
			NET USE $to /D
		}		
	}
}