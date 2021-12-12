#Requires -PSEdition Core
#Requires -Version 7.0
#Requires -RunAsAdministrator

using namespace System.Net
<#
.SYNOPSIS
Setup prescribed directory structure to support terraform workflows

.DESCRIPTION
This script will create a directory structure to support Terraform workflows

.PARAMETER LogDirectory
Directory for transcript. The default directory of $env:USERPROFILE, which resolves to <SystemDrive>:\users\<userid>\


.EXAMPLE
.\Set-TerraformWorkflowPrerequisites.ps1 -Verbose

Use the default $env:USERPROFILE location as the log directory for the transcript.

.EXAMPLE
.\Set-TerraformWorkflowPrerequisites.ps1 -LogDirectory <path> -Verbose 

Override the default $env:USERPROFILE location with a user defined (custom) log path instead

.NOTES
The MIT License (MIT)
Copyright (c) 2021 Preston K. Parsard

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

LEGAL DISCLAIMER:
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. 
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. 
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree:
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys' fees, that arise or result from the use or distribution of the Sample Code.
This posting is provided "AS IS" with no warranties, and confers no rights.

.LINK
1. https://stackoverflow.com/questions/957928/is-there-a-way-to-get-the-git-root-directory-in-one-command

.COMPONENT
File system

.ROLE
Systems Engineer
DevOps Engineer
Cloud Engineer

.FUNCTIONALITY
Create a directory structure to support Terraform workflows
#>

<#
TASK-ITEMS:
001. Set $env:TF_DATA_DIR = .\live\glb
002. Change the live directory name to env
#>

[CmdletBinding()]
param (
		# Log directory
		# i.e. "\\server\share\logs"
        [string]$LogDirectory = $env:USERPROFILE,
		[string]$resourceGroupName = "tf-shared-rgp-01",
		[string]$region = "eastus2",
		[string]$staPrefix = "1tfm",
		[string]$staContainer = "dev-tfstate",
		[string]$tfstateKey = "dev.tfstate",
		[string]$tfConfigFile = "backend.tf",
		[string]$resourceInfix = ((New-Guid).Guid).Substring(0,8),
		[string]$PSModuleRepository = "PSGallery"
) #end param

#region INITIALIZE ENVIRONMENT
# Set-StrictMode -Version Latest
#endregion INITIALIZE ENVIRONMENT

#region FUNCTIONS

function Connect-ToAzSubscription 
{
	[CmdletBinding()]
	param()

	Write-Output "Please see the open dialogue box in your browser to authenticate to your Azure subscription..."

	# Clear any possible cached credentials for other subscriptions
	Clear-AzContext

	# Authenticate to subscription
	Connect-AzAccount

	Do
	{
		# TASK-ITEM: List subscriptions
		(Get-AzSubscription).Name
		[string]$Subscription = Read-Host "Please enter your subscription name, i.e. [MySubscriptionName] "
		$Subscription = $Subscription.ToUpper()
	} #end Do
	Until ($Subscription -in (Get-AzSubscription).Name)
	Select-AzSubscription -SubscriptionName $Subscription -Verbose
	$subscriptionId = (Select-AzSubscription -SubscriptionName $Subscription).Subscription.id
}

function New-AzTerraformBackend 
{
	[CmdletBinding()]
	param (
		[backend]$backendConfig
	)

	$rgpName = (Get-AzResourceGroup -Name $backendConfig.rgp -Location $backendConfig.location -ErrorAction SilentlyContinue).ResourceGroupName

	if ($null -eq $rgpName)
	{
		# Create resource group
		New-AzResourceGroup -Name $backendConfig.rgp -Location $backendConfig.location -ErrorAction SilentlyContinue -Verbose 
	}
	
	$staName = (Get-AzStorageAccount -ResourceGroup $backendConfig.rgp).StorageAccountName 
	if ($staName -notmatch $backendConfig.staPfx)
	{
		# Create storage account 
		$storageAccount = New-AzStorageAccount -ResourceGroup $backendConfig.rgp -Name $backendConfig.staName -Location $backendConfig.location -Type $backendConfig.storageSku -Verbose

		# Create container if required
		$staContext = $storageAccount.Context 
		if (-not(Get-AzStorageContainer -Name $backendConfig.container -Context $staContext -ErrorAction SilentlyContinue))
		{
			New-AzStorageContainer -Name $backendConfig.container -Context $staContext -Verbose -ErrorAction SilentlyContinue
		}
	}
}

function New-LogFiles
{
	[CmdletBinding()]
	[OutputType([string[]])]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$LogDirectory,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$LogPrefix
	) # end param

	# Get curent date and time
	$TimeStamp = (get-date -format u).Substring(0,16)
	$TimeStamp = $TimeStamp.Replace(" ", "-")
	$TimeStamp = $TimeStamp.Replace(":", "")

	$subDir = Join-Path $LogDirectory -ChildPath $LogPrefix
	
	if (-not(Test-Path -Path $subDir))
	{
		New-Item -Path $subDir -ItemType Directory -Verbose
	}

	# Construct transcript file full path
	$TranscriptFile = "$LogPrefix-TRANSCRIPT" + "-" + $TimeStamp + ".log"
	$script:Transcript = Join-Path -Path $subDir -ChildPath $TranscriptFile

	# Create log and transcript files
	New-Item -Path $Transcript -ItemType File -ErrorAction SilentlyContinue
} # end function

function script:New-Header
{
	[CmdletBinding()]
	[OutputType([hashtable])]
	param (
		[Parameter(Mandatory=$true)]
		[string]$label,
		[Parameter(Mandatory=$true)]
		[int]$charCount
	) # end param

	$script:header = @{
		# Draw double line
		SeparatorDouble = ("=" * $charCount)
		Title = ("$label :" + " $(Get-Date)")
		# Draw single line
		SeparatorSingle = ("-" * $charCount)
	} # end hashtable

} # end function

function New-PromptObjects
{
	# Create prompt and response objects
	[CmdletBinding()]
	param (
	[AllowNull()]
	[AllowEmptyCollection()]
	[PScustomObject]$PromptsObj,

	[AllowNull()]
	[AllowEmptyCollection()]
	[PScustomObject]$ResponsesObj
	) # end param

	# Create and populate prompts object with property-value pairs
	# PROMPTS (PromptsObj)
	$script:PromptsObj = [PSCustomObject]@{
		 pVerifySummary = "Is this information correct? [YES/NO]"
		 pAskToOpenLogs = "Would you like to open the custom and transcript logs now ? [YES/NO]"
	} #end $PromptsObj

	# Create and populate responses object with property-value pairs
	# RESPONSES (ResponsesObj): Initialize all response variables with null value
	$script:ResponsesObj = [PSCustomObject]@{
		 pProceed = $null
		 pOpenLogsNow = $null
	} #end $ResponsesObj
} # end function

function New-TerraformDirectories
{
	[CmdletBinding()]
	param (
		[hashtable]$dirs # Hashtable of directories to create
	)

	if (-not(Test-Path -Path "$($dirs.top)\$($dirs.lve)"))
	{
		New-Item -Path $dirs.lve -ItemType Directory -Verbose -ErrorAction SilentlyContinue
	}

	if (Test-Path -Path $dirs.lve -ErrorAction SilentlyContinue)
	{
		$devPath = Join-Path -Path $dirs.lve -ChildPath $dirs.dev  
		$stgPath = Join-Path -Path $dirs.lve -ChildPath $dirs.stg 
		$prdPath = Join-Path -Path $dirs.lve -ChildPath $dirs.prd
		$glbPath = Join-Path -Path $dirs.lve -ChildPath $dirs.glb 
		$envPaths = @($devPath,$stgPath,$prdPath,$glbPath)
		$envPaths | ForEach-Object {New-Item -Path $_ -ItemType Directory -Verbose -ErrorAction SilentlyContinue}
		$devSvcPath = Join-Path -Path $devPath -ChildPath $dirs.svc
		if (Test-Path -Path $devPath)
		{
			New-Item -Path $devSvcPath -ItemType Directory -Verbose -ErrorAction SilentlyContinue
		}
		else 
		{
			Write-Output "The directory $devPath was not found."
		}
	}
	else 
	{
		Write-Output "The directory $($dirs.lve) was not found."
	}
	
	$modDir = "$($dirs.top)\$($dirs.mod)"
	if (-not(Test-Path -Path $modDir))
	{
		New-Item -Path $modDir -ItemType Directory -Verbose -ErrorAction SilentlyContinue
	}

	$modSubDirs = @("examples","modules","test")
	foreach ($dir in $modSubDirs) 
	{
		$targetSubDir = Join-Path -Path $modDir -ChildPath $dir -Verbose
		New-Item -Path $targetSubDir -ItemType Directory -Verbose -ErrorAction SilentlyContinue
	}
}
#endregion FUNCTIONs

function Set-EnvironmentVariables
{
	[CmdletBinding()]
	param(
		[hashtable]$tfDirs
	)

	$tfLogFile = "tf.log"
	$fullCurrentPath = (Resolve-Path -Path $tfDirs.top).Path 
	$tfLogDirLve = Join-Path -Path $fullCurrentPath -ChildPath $tfDirs.lve
	$tfLogDir = Join-Path -Path $tfLogDirLve -ChildPath $tfDirs.glb 
	$tfLogPath = Join-Path -Path $tfLogDir -ChildPath $tfLogFile

	if (Test-Path -Path $tfLogDir) 
	{
		if (-not(Test-Path -Path $tfLogPath))
		{
			New-Item -Path $tfLogPath -ItemType File -Force -Verbose
		}
		$env:TF_LOG = "INFO"
		$env:TF_LOG_PATH = $tfLogPath
		$env:TF_DATA_DIR = $tfLogDir
	}
	else
	{
		Write-Output "Can't find Terraform log directory: $tfLogDir"
	}

	if (git --version)
	{
		$env:gitRoot = Invoke-Command -ScriptBlock { git rev-parse --show-toplevel } 
	}
	else
	{
		"Unable to set the $env:GitRoot variable because git is not installed. Please install git from: https://git-scm.com/downloads"
	}
}

#region INITIALIZE VALUES

# Create Log file
[string]$Transcript = $null

$scriptName = $MyInvocation.MyCommand.name
# Use script filename without exension as a log prefix
$LogPrefix = $scriptName.Split(".")[0]

# funciton: Create log files for custom logging and transcript
New-LogFiles -LogDirectory $LogDirectory -LogPrefix $LogPrefix

Start-Transcript -Path $Transcript -IncludeInvocationHeader

# Create prompt and response objects for continuing script and opening logs.
$PromptsObj = $null
$ResponsesObj = $null

# function: Create prompt and response objects
New-PromptObjects -PromptsObj $PromptsObj -ResponsesObj $ResponsesObj

$BeginTimer = Get-Date -Verbose

# Create PSClass class to track status of changes during processing

class PSClass
{
	[type]$property = $null
} # end class

# Initialize index
$i = 0
# Initialize list of status objects
$resultSet = @()

# Populate summary display object
# Add properties and values
 $SummObj = [PSCustomObject]@{
     Transcript = $Transcript
 } #end $SummObj

 # funciton: Create new header
 $label = "SETUP TERRAFORM PRE-REQUISITES"
 New-Header -label $label -charCount 100

 # function: Create prompt and responses objects ($PromptsObj, ResponsesObj)
 New-PromptObjects

 #endregion INITIALIZE VALUES

#region MAIN
# Display header
Write-Output $header.SeparatorDouble
Write-Output $Header.Title
Write-Output $header.SeparatorSingle

# Display Summary of initial parameters and constructed values
Write-Output $SummObj
Write-Output $header.SeparatorDouble

Do {
	$ResponsesObj.pProceed = read-host $PromptsObj.pVerifySummary
	$ResponsesObj.pProceed = $ResponsesObj.pProceed.ToUpper()
} # end do
Until ($ResponsesObj.pProceed -eq "Y" -OR $ResponsesObj.pProceed -eq "YES" -OR $ResponsesObj.pProceed -eq "N" -OR $ResponsesObj.pProceed -eq "NO")

# Record prompt and response in log
Write-Output $PromptsObj.pVerifySummary
Write-Output $ResponsesObj.pProceed

#region Environment setup
# Use TLS 1.2 to support Nuget provider
Write-Output "Configuring security protocol to use TLS 1.2 for Nuget support when installing modules." -Verbose
[ServicePointManager]::SecurityProtocol = [SecurityProtocolType]::Tls12
#endregion

# Exit if user does not want to continue
if ($ResponsesObj.pProceed -eq "N" -OR $ResponsesObj.pProceed -eq "NO")
{
	Write-Output "Script terminated by user..."
	PAUSE
	EXIT
} #end if ne Y
else
{
#region MODULES
	# Module repository setup and configuration
	Set-PSRepository -Name $PSModuleRepository -InstallationPolicy Trusted -Verbose
	# Install-PackageProvider -Name Nuget -ForceBootstrap -Force

	# Bootstrap dependent modules
	$desiredModule = "Az"
	if (Get-InstalledModule -Name $desiredModule -ErrorAction SilentlyContinue)
	{
		# If module exists, update it
		[string]$currentVersionADM = (Find-Module -Name $desiredModule -Repository $PSModuleRepository).Version
		[string]$installedVersionADM = (Get-InstalledModule -Name $desiredModule).Version
		If ($currentVersionADM -ne $installedVersionADM)
		{
				# Update modules if required
				Update-Module -Name $desiredModule -Force -ErrorAction SilentlyContinue -Verbose
		} # end if
	} # end if
	# If the modules aren't already loaded, install and import it.
	else
	{
		Install-Module -Name $desiredModule -Repository $PSModuleRepository -Force -Verbose
	} #end If
	Import-Module -Name $desiredModule -Verbose
	#endregion MODULES
	
	Connect-ToAzSubscription -Verbose
	
	$directories = @{
		top = "." # Top level directory
		lve = "env" # Live environments, i.e. dev, stage and production
		mod = "mod" # Terraform modules
		dev = "dev"	# Development
		stg = "stg"	# Staging
		prd = "prd"	# Production
		glb = "glb" # Global or shared resources/services that are common for all environments (dev/stg/prd)
		svc = "svc" # Service, which represents a set of resources that is a distinct component of the overall infrastrucuture. Rename this folder to the actual service name.
	}

	New-TerraformDirectories -Dirs $directories -Verbose

	Do
	{
		$randomInfix = (New-Guid).Guid.Replace("-","").Substring(0,8)
		$StorageAccountName = $staPrefix + $randomInfix
	} #end while
	While (-not((Get-AzStorageAccountNameAvailability -Name $StorageAccountName).NameAvailable))

	$backendConfigDir = Join-Path -Path "$($directories.top)\$($directories.lve)" -ChildPath $directories.glb 
	$backendFilePath = Join-Path -Path $backendConfigDir -ChildPath $tfConfigFile
	# Terraform variable references can't be used for the backend configuration, so these must be resolved dynamically and hardcoded in the terraform.tf file.
	$backendFileContent = @"
// backend state file
terraform {
  backend "azurerm" {
      resource_group_name = "$resourceGroupName"
      storage_account_name = "$storageAccountName"
      container_name = "$staContainer"
      key = "$tfStateKey"
  }
}
"@

	Class backend
	{
		[string]$rgp = $resourceGroupName 
		[string]$location = $region
		[string]$staName = $StorageAccountName
		[string]$container = $staContainer 
		[string]$key = $tfstateKey
		[string]$configFile = $backendFilePath
		[string]$configFileContent = $backendFileContent
		[string]$storageSku = "Standard_LRS"
		[string]$staPfx = $staPrefix
	} # end class

	$tfstateConfig = [backend]::new()

	New-AzTerraformBackend -backendConfig $tfstateConfig -Verbose 

	if (-not(Test-Path -Path $backendFilePath))
	{
		New-Item -Path $backendFilePath -ItemType File -Verbose 
	}
	
	$fileContent = (Get-Content -Path $backendFilePath) 
	if (-not($fileContent -match $storageAccountName))
	{
		Set-Content -Path $backendFilePath -Value $backendFileContent -Verbose
	}

	# To delete the new folder structure (when testing only or to cleanup) uncomment the following commands below and execute the following commands after pausing to verify that the folders were created
	<#
	pause
	$topLevelDirectories = @(".\$($dirs.lve)",".\$($dirs.mod)")
	$topLevelDirectories | ForEach-Object { Remove-Item -Path $_ -Recurse -Verbose -Confirm:$false }
	#>

} # end else

Set-TerraformEnvVarsForLogging -tfDirs $directories -Verbose

#endregion MAIN

#region SUMMARY

<#
# Calculate statistics using percentages
$score = [PScustomObject]@{
} # end count objects

# Display count statistics
$countObj | Format-Table -AutoSize
# Display score
$score | Format-Table -AutoSize
#>

# Calculate elapsed time
Write-Output "Calculating script execution time..."
Write-Output "Getting current date/time..."
$StopTimer = Get-Date
$EndTime = (((Get-Date -format u).Substring(0,16)).Replace(" ", "-")).Replace(":","")
Write-Output "Calculating elapsed time..."
$ExecutionTime = New-TimeSpan -Start $BeginTimer -End $StopTimer

$Footer = "SCRIPT COMPLETED AT: "
$EndOfScriptMessage = "End of script!"

Write-Output $header.SeparatorDouble
Write-Output "$Footer $EndTime"
Write-Output "TOTAL SCRIPT EXECUTION TIME [hh:mm:ss]: $ExecutionTime"
Write-Output $header.SeparatorDouble

Stop-Transcript -ErrorAction SilentlyContinue -Verbose

# Review deployment logs
# Prompt to open logs
Do
{
 $ResponsesObj.pOpenLogsNow = read-host $PromptsObj.pAskToOpenLogs
 $ResponsesObj.pOpenLogsNow = $ResponsesObj.pOpenLogsNow.ToUpper()
}
Until ($ResponsesObj.pOpenLogsNow -eq "Y" -OR $ResponsesObj.pOpenLogsNow -eq "YES" -OR $ResponsesObj.pOpenLogsNow -eq "N" -OR $ResponsesObj.pOpenLogsNow -eq "NO")

# Exit if user does not want to continue
If ($ResponsesObj.pOpenLogsNow -in 'Y','YES')
{
    Start-Process -FilePath notepad.exe $Transcript -Verbose
	# Invoke-Item -Path $resultsPathCsv -Verbose
    Write-Output $EndOfScriptMessage
} #end condition
ElseIf ($ResponsesObj.pOpenLogsNow -in 'N','NO')
{
    Write-Output $EndOfScriptMessage
} #end condition

#endregion SUMMARY