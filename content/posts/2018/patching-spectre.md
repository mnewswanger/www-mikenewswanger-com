---
title: Patching Processes for Meltdown & Spectre
date: 2018-01-13T09:00:00-05:00
tags: [performance, security]
description: Patching process for Meltdown and Spectre mitigations.
---

In order to mitigate against Meltdown, a CPU microcode update needs to be applied, which is delivered via BIOS.  MacOS updates will do this via the standard update process.  For Linux and Windows, BIOS updates will need to be run in addition to the operating system patches.  In our case, we were running 13th generation Dell servers (R630) and deployed BIOS version 2.7.0 ~~(which has since been pulled by Dell)~~. _Update (1/13/18): 2.7.0 is once again available for download, but this time with a release date of January 12._  When patching, I installed the Windows patch and BIOS update then set the registry key prior to rebooting so that the system only had to reboot once during the patching process.  It doesn't have to be done that way, but that minimized downtime for our instances.

## Windows Server ##

Server patches for fixing Meltdown and known Spectra variants are available on <a href="https://support.microsoft.com/en-us/help/4072698/windows-server-guidance-to-protect-against-the-speculative-execution" target="_blank" rel="nofollow">Microsoft's Meltdown & Spectre mitigation instructions</a> under the "Recommended Actions" heading.

After the server is patched, the fixes must be manually enabled.  Note: Windows desktop operating systems enable by default after the patch is installed.
```
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" /v MinVmVersionForCpuBasedMitigations /t REG_SZ /d "1.0" /f
```

If the fix has previously been enabled and needs to be disabled, the following will turn off the fix:
```
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f
```

### Verifying the Installation ###

Run the following PowerShell script as an administrator:
```powershell
Install-Module SpeculationControl
```

Then run the following as a regular user account:
```powershell
Import-Module SpeculationControl
Get-SpeculationControlSettings
```

The resulting output should look like this:

Spectre:
```powershell
Hardware support for branch target injection mitigation is present: True
Windows OS support for branch target injection mitigation is present: True
Windows OS support for branch target injection mitigation is enabled: True
```

Meltdown:
```powershell
Hardware requires kernel VA shadowing: True
Windows OS support for kernel VA shadow is present: True
Windows OS support for kernel VA shadow is enabled: True
Windows OS support for PCID optimization is enabled: True
```

## Linux ##

Meltdown and Spectre software patches should be delivered in kernel updates via package managers (i.e. apt or yum) for Linux systems.

To check the running kernel version, run `uname -r`.

Centos 7 patches are present beginning in kernel version `3.10.0-693.11.6.el7`.

## MacOS ##

Meltdown and Spectre mitigations are present in 10.13.2 (released December 2017) with a supplemental update available January 8 to mitigate exploitation via Safari and Webkit.  These can and should be installed via the App Store apps.
