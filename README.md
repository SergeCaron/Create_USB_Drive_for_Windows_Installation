# Create_USB_Drive_for_Windows_Installation
Create USB Drive for Windows Installation
 
Purpose:	Quickly create a UEFI or MBR installation media on a USB key without
		regards to the size of the original Microsoft install.wim file.
			
Caution:	This script requires elevated execution privileges.
			
		Quoting from Microsoft's "about_Execution_Policies" : "PowerShell's
		execution policy is a safety feature that controls the conditions
		under which PowerShell loads configuration files and runs scripts."
		
		In order to execute this script using a right-click "Run with PowerShell",
		the user's session must be able to run unsigned scripts and perform
		privilege elevation. Use any configuration that is the equivalent of the
		following commnand executed from an elevated PowerShell prompt:
			
			Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
			
Operation:	- Start the script using your method of choice.
		- Locate the Windows Installation ISO for which you want a USB key
		- Insert a USB key and press ENTER
		- Specify the BIOS boot architecture (MBR or UEFI)
		- Confirm the operation ;-)
			
Here is a sample output:

```
	Create USB Drive for Windows Installation
	Please insert a USB key and press Enter:

	Number         : 1
	FriendlyName   : SanDisk Ultra
	Size in GB     : 29
	PartitionStyle : GPT

	Boot to UEFI Mode or legacy BIOS mode?
	[M] MBR  [U] UEFI  [?] Aide (la valeur par défaut est « M ») : U

	Confirmer
	Êtes-vous sûr de vouloir effectuer cette action ?
	This will erase all data on disk 1 "SanDisk Ultra".
	[O] Oui  [T] Oui pour tout  [N] Non  [U] Non pour tout  [S] Suspendre  [?] Aide (la valeur par défaut est « O ») : O

	Number Friendly Name Serial Number                    HealthStatus         OperationalStatus      Total Size Partition Style
	------ ------------- -------------                    ------------         -----------------      ---------- ---------------
	1      SanDisk Ultra 4C530001151201103511             Healthy              Online                   28.64 GB GPT

	Deployment Image Servicing and Management tool
	Version: 10.0.22621.2792

	The operation completed successfully.

	Attached          : False
	BlockSize         : 0
	DevicePath        :
	FileSize          : 5216358400
	ImagePath         : \\[...]\SW_DVD9_Win_Pro_11_21H2_64BIT_FrenchCanadian_Pro_Ent_EDU_N_MLF_-3_X22-89967.ISO
	LogicalSectorSize : 2048
	Number            :
	Size              : 5216358400
	StorageType       : 1
	PSComputerName    :

	Cliquez sur Entrée pour continuer...:
```
