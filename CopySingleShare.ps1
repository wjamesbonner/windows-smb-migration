param (
[string] $source = "",
[string] $sourceUsername = "",
[string] $sourcePasswordInput = "",
[switch] $sourceNetUse = $true,
[string] $destination = "",
[string] $destinationUsername = "",
[string] $destinationPasswordInput = "",
[switch] $destinationNetUse = $true,
[switch] $destructive = $false
)

if ($source -eq "") {
	$source = Read-Host "Enter the source server (\\server\folder)"
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
	$destination = Read-Host "Enter the destination server (\\server\folder)"
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

if($sourceNetUse -eq $true) {
	NET USE $source /u:$sourceUsername $([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sourcePassword)))
}

if($destinationNetUse -eq $true) {
	NET USE $destination /u:$destinationUsername $([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($destinationPassword)))
}

if ($destructive -eq $true) {
	# Do a destructive mirroring from source to destination
	robocopy $source $destination /E /MIR /SEC /FFT /R:3 /W:10 /MT:10 /Z /NP /NDL /XD `#* /XF "$to\#MigrationStatus.txt" /LOG:"$to\#MigrationStatus.txt" 
} else {
	# Do a non-destructive copy from source to destination
	robocopy $source $destination /E /XO /SEC /FFT /R:3 /W:10 /MT:10 /Z /NP /NDL /XD `#* /XF "$to\#MigrationStatus.txt" /LOG:"$to\#MigrationStatus.txt" 
}
		
if($sourceNetUse -eq $true) {
	NET USE $source /D
}

if($destinationNetUse -eq $true) {
	NET USE $destination /D
}		
