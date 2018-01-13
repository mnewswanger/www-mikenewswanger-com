---
title: Patching Meltdown & Spectre at Stack Overflow - Round 1
date: 2018-01-13T09:00:00-05:00
draft: true
tags: [performance, security]
description: Overview of the implementation process and performance hits of Meltdown and Spectre Patches on Stack Overflow's Web Servers.
---

Announced early in the year, Meltdown and Spectre processor vulnerabilities affect nearly all servers and consumer PCs.  At Stack Overflow, we've done some testing on the impact of software mitigations desinged to protect against these vulnerabilities.  Software patches are available for Meltdown and known attack vectors of Spectre, and we'll take a look at their impact on system performance below.

### Overview of Vulnerabilities ###

#### Meltdown ####

Meltdown is a hardware-level vulnerability that allows userspace programs to access protected kernel memory affecting all modern Intel processors and some ARM processors.  Operating systems mitigate this vulnerability via software level memory isolation protections, and patches are available for MacOS, Windows, and most Linux distributions now.

#### Spectre ####

In a very simplified explanation: in order to boost performance, most modern processors take in multiple instructions at a time from the operating system.  Assumptions can be exploited, and protected data can be leaked from vulnerable systems.  This is the Spectre vulnerability, which derives its name from Speculative Execution.  If you want to learn more about how branch prediction works, Dan Luu has <a href="https://danluu.com/branch-prediction/" target="_blank" rel="nofollow">an excellent, much more in-depth explaination of how branch prediction works here</a>.  Spectre is much more complicated both in exploitation and patching.  Mitigation require both processor microcode update (BIOS) and an operating system patch.

### Patching Steps ###

## Impact ##

### Server Loads ###

### Performance Impact ###

## Takeaways ##

### Recommendations ###

### Conclusion ###

### Related Links ###

* <a href="https://meltdownattack.com/" target="_blank" rel="nofollow">Meltdown & Spectre Vulnerability Site</a>
* <a href="https://danluu.com/branch-prediction/" target="_blank" rel="nofollow">Explanation of Branch Prediction</a>
* <a href="https://support.microsoft.com/en-us/help/4072698/windows-server-guidance-to-protect-against-the-speculative-execution" target="_blank" rel="nofollow">Microsoft Patching Guide for Spectre & Meltdown</a>
