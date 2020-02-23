
﻿$ErrorActionPreference = 'Stop'
# This is the general install script for Mozilla products (Firefox and Thunderbird).
# This file must be identical for all Choco packages for Mozilla products in this repository.
$toolsPath = Split-Path $MyInvocation.MyCommand.Definition
. $toolsPath\helpers.ps1

$packageName = 'Firefox'
$softwareName = 'Mozilla Firefox'

$alreadyInstalled = (AlreadyInstalled -product $softwareName -version '73.0.1')

if (Get-32bitOnlyInstalled -product $softwareName) {
  Write-Output $(
    'Detected the 32-bit version of Firefox on a 64-bit system. ' +
    'This package will continue to install the 32-bit version of Firefox ' +
    'unless the 32-bit version is uninstalled.'
  )
    $installPath = "${env:ProgramFiles(x86)}"
}

function Get-SilentArguments {
param(
    [hashtable]$pp = ( Get-PackageParameters )
)

$New_pp = @(); 
# The presence of any command-line option implicitly enables silent mode
if ([string]::IsNullOrEmpty($pp)){ $New_pp += "-ms" }

$firefox_switches = @("InstallDirectoryPath","InstallDirectoryName","TaskbarShortcut","DesktopShortcut","StartMenuShortcut","MaintenanceService","RemoveDistributionDir","PreventRebootRequired","OptionalExtensions","INI","ExtractDir")

    foreach ($key in $pp.GetEnumerator()) {
            foreach ($switch in $firefox_switches) {
            if ( $($key.Name) -eq $switch ) { 
                $New_pp += "/" + $($key.Name) + " = " + $($key.Value)
            }
        }
    }
    return $New_pp
}

  $locale = 'en-US' #https://github.com/chocolatey/chocolatey-coreteampackages/issues/933
  $locale = GetLocale -localeFile "$toolsPath\LanguageChecksums.csv" -product $softwareName
  $checksums = GetChecksums -language $locale -checksumFile "$toolsPath\LanguageChecksums.csv"

  $packageArgs = @{
    packageName    = $packageName
    fileType       = 'exe'
    softwareName   = "$softwareName*"
    Checksum       = $checksums.Win32
    ChecksumType   = 'sha512'
    Url            = "https://download.mozilla.org/?product=firefox-73.0.1-ssl&os=win&lang=${locale}"
    silentArgs     = ( Get-SilentArguments )
    validExitCodes = @(0)
  }
	
  if (!(Get-32bitOnlyInstalled($softwareName)) -and (Get-OSArchitectureWidth 64)) {
    $installPath = "${env:ProgramFiles}"
    $packageArgs.Checksum64 = $checksums.Win64
    $packageArgs.ChecksumType64 = 'sha512'
    $packageArgs.Url64 = "https://download.mozilla.org/?product=firefox-73.0.1-ssl&os=win64&lang=${locale}"
  }

  Install-ChocolateyPackage @packageArgs

if (-Not(Test-Path ($installPath + "\Mozilla Firefox\distribution\policies.json") -ErrorAction SilentlyContinue) -and ($PackageParameters.NoAutoUpdate) ) {
  if (-Not(Test-Path ($installPath + "\Mozilla Firefox\distribution") -ErrorAction SilentlyContinue)) {
    new-item ($installPath + "\distribution") -itemtype directory
  }

  $policies = @{
    policies = @{
      "DisableAppUpdate" = $true
    }
  }
  $policies | ConvertTo-Json | Out-File -FilePath ($installPath + "\distribution\policies.json") -Encoding ascii

}
