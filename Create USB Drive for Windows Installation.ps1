##******************************************************************
## Revision date: 2025.02.03
##
##		2021.04.01: Proof of concept / Initial release
##		2024.01.31: Default to UEFI instead of MBR
##		2025.02.03:	Allow ESD and WIM extensions in Windows Imaging files
##					Display inventory of the Windows image
##					Do not use .Net [math]
##
## Copyright (c) 2021-2024 PC-Évolution enr.
## This code is licensed under the GNU General Public License (GPL).
##
## THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
## ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
## IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
## PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
##
##******************************************************************

# Create a USB thumbdrive from a Microsoft Windows installation ISO.

# Credits:	The basic idea frot this script came from Thomas Maurer.
#			https://www.thomasmaurer.ch/2018/07/create-a-usb-drive-for-windows-server-2019-installation/
#
#			The code was updated to support MBR and UEFI partitions while allowing execution from a simple
#			right-click "Run with PowerShell..." 


# Privilege Elevation Source Code: https://stackoverflow.com/questions/7690994/running-a-command-as-administrator-using-powershell

# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

# Check to see if we are currently running as an administrator
if ($myWindowsPrincipal.IsInRole($adminRole)) {
	# We are running as an administrator, so change the title and background colour to indicate this
	$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
	$Host.UI.RawUI.BackgroundColor = "DarkBlue"
	Clear-Host
}
else {
	# We are not running as an administrator, so relaunch as administrator

	# Create a new process object that starts PowerShell
	$newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"

	# Specify the current script path and name as a parameter with added scope and support for scripts with spaces in it's path
	$newProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"

	# Indicate that the process should be elevated
	$newProcess.Verb = "runas"

	# Start the new process
	[System.Diagnostics.Process]::Start($newProcess)

	# Exit from the current, unelevated, process
	Exit
}

# Run your code that needs to be elevated here...

Write-Output "Create USB Drive for Windows Installation"

# Define Path to the Windows ISO

Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
	InitialDirectory = [Environment]::GetFolderPath('Desktop')
}
$FileBrowser.Filter = 'Distribution media (*.iso)|*.iso'
$FileBrowser.Title = "Locate the Windows distribution media image"
[void]$FileBrowser.ShowDialog()
If ($FileBrowser.FileName -eq "") {
	Write-Output "Aborting at user's request ..."
	Pause
	Exit 911
}
	
$ISOFile = $FileBrowser.FileName

 
# Get the USB Drive you want to use
Do {
	$USBDrive = Get-Disk | Where-Object BusType -EQ "USB"
	# Avoid prompting if drive is already inserted ;-)
	If ($Null -eq $USBDrive)
	{ Read-Host "Please insert a USB key and press Enter" }
	else {
		# Display the attributes: there may be more than one USB disk!
		$USBDrive | Format-List Number, FriendlyName, @{name = 'Size in GB'; expr = { [int]($_.size / 1GB) } }, PartitionStyle
		 
		# Get the right USB Drive
		If ( $USBDrive.GetType().BaseType.Name -eq "Array" ) {
			Try { [int]$DriveNumber = Read-Host "Enter drive number to overwrite" }
			Catch { [int]$DriveNumber = 0 }

			$USBDrive = Get-Disk | Where-Object { ($_.BusType -eq "USB") -and ($_.Number -eq $DriveNumber) }
			Try {
				If ( $USBDrive.GetType().BaseType.Name -eq "Object") {
					Write-Output "Selected USB key:"
					$USBDrive | Format-List Number, FriendlyName, @{name = 'Size in GB'; expr = { [int]($_.size / 1GB) } }, PartitionStyle
				}
			}
			Catch {
				Write-Output "No such drive!"
				$USBDrive = $Null
			}
		}
	}
} while ($Null -eq $USBDrive)

# Select Boot Mode
$TypeUEFI = New-Object System.Management.Automation.Host.ChoiceDescription '&UEFI', 'Partitiontype: UEFI'
$TypeMBR = New-Object System.Management.Automation.Host.ChoiceDescription '&MBR', 'Partitiontype: MBR'
If ([math]::ceiling($USBDrive.Size / 1GB) -gt 32) {
	Write-Output "Native tools do not support UEFI on USB keys larger than 32GB."
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($TypeMBR)
}
else { $options = [System.Management.Automation.Host.ChoiceDescription[]]($TypeMBR, $TypeUEFI) }
$BootMode = $host.ui.PromptForChoice('', 'Boot to UEFI Mode or legacy BIOS mode?', $options, 1)
 
# Mount ISO
$ISOMounted = Mount-DiskImage -ImagePath $ISOFile -StorageType ISO -PassThru
 
# Driver letter
$ISODriveLetter = ($ISOMounted | Get-Volume).DriveLetter
 
# Clean the USB Drive (THIS WILL REMOVE EVERYTHING)
$USBDrive | Clear-Disk -RemoveData -Confirm:$true -PassThru

switch ($BootMode) {
	0 {
		#------------------------
		# Convert Disk to MBR
		$USBDrive | Set-Disk -PartitionStyle MBR
		 
		# Create partition primary and format to NTFS
		$Volume = $USBDrive | New-Partition -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel USBInstall
		 
		# Set Partiton to Active
		$Volume | Get-Partition | Set-Partition -IsActive $true
		 
		# Copy Files to USB
		Copy-Item -Path ($ISODriveLetter + ":\*") -Destination ($Volume.DriveLetter + ":\") -Recurse -ErrorAction SilentlyContinue -ErrorVariable $Junk
	}
	1 {
		#-----------------------------
		# Convert Disk to GPT
		$USBDrive | Set-Disk -PartitionStyle GPT
		 
		# Create partition primary and format to FAT32
		$Volume = $USBDrive | New-Partition -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem FAT32 -NewFileSystemLabel USBInstall
		 
		# Copy Files to USB 
		Copy-Item -Path ($ISODriveLetter + ":\*") -Destination ($Volume.DriveLetter + ":\") -Recurse -ErrorAction SilentlyContinue -ErrorVariable $Junk

		# Display directory of imaging file
		$ImagingFile = $ISODriveLetter + ":\sources\install."
		$ImagingFile += If ( Test-Path -Path $($ImagingFile + "wim") -PathType leaf) { "wim" } else { "esd" }
		dism /Get-ImageInfo /ImageFile:$ImagingFile

		# Split image files larger than the maximum FAT32 file size
		If ((Get-Item $ImagingFile).Length -gt (4GB - 4096)) {
			# Split Install
			$SWMFile = $Volume.DriveLetter + ":\sources\install.swm"
			dism /Split-Image /ImageFile:"$ImagingFile" /SWMFile:"$SWMFile" /FileSize:4096
		}
	}
}

# It is unclear if ErrorVariable is populated while ErrorAction SilentlyContinue is set.
Write-Output $Junk
 
# Dismount ISO
Dismount-DiskImage -ImagePath $ISOFile

Pause

exit
