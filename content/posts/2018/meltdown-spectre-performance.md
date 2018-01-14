---
title: Meltdown & Spectre Performance Impact at Stack Overflow
date: 2018-01-13T09:00:00-05:00
draft: true
tags: [performance, security]
description: Overview of the implementation process and performance hits of Meltdown and Spectre Patches on Stack Overflow's Web Servers.
---

Announced early in the year, Meltdown and Spectre processor vulnerabilities affect nearly all servers and consumer PCs.  As of now, attacks are only proof-of-concept, and no known exploits are in the wild.  At Stack Overflow, we've done some testing on the impact of software mitigations desinged to protect against these vulnerabilities.  Software patches are available for Meltdown and known attack vectors of Spectre, and we'll take a look at their impact on system performance below.  If you're already familiar with the vulnerabilities and how to patch them, jump down to the <a href="#impact">Impact Section</a>.

Two of the interesting things about this particular set of vulnerabilities are that 1) there's a significant performance hit to enable mitigations for them and 2) it's been very difficult for hardware and software vendors to perpare and deploy mitigations.  While the details of these vulnerabilites have only been public since early 2018, <a href="https://googleprojectzero.blogspot.co.at/2018/01/reading-privileged-memory-with-side.html" target="_blank" rel="nofollow">Google's Project Zero initiative discovered them in July 2017</a>, allowing core software vendors six months to prepare mitigations.

For details about the processes to patch against the vulnerabilies, <a href="/posts/2018/patching-spectre/">see this page</a>.

### Overview of Vulnerabilities ###

#### Meltdown ####

Meltdown is a hardware-level vulnerability that allows userspace programs to access protected kernel memory affecting all modern Intel processors and some ARM processors.  Operating systems mitigate this vulnerability via software level memory isolation protections, and patches are available for MacOS, Windows, and most Linux distributions now.

#### Spectre ####

In a very simplified explanation: in order to boost performance, most modern processors take in multiple instructions at a time from the operating system.  Assumptions can be exploited, and protected data can be leaked from vulnerable systems.  This is the Spectre vulnerability, which derives its name from Speculative Execution.  If you want to learn more about how branch prediction works, Dan Luu has <a href="https://danluu.com/branch-prediction/" target="_blank" rel="nofollow">an excellent, much more in-depth explaination of how branch prediction works here</a>.  Spectre is much more complicated both in exploitation and patching.  Mitigation require both processor microcode update (BIOS) and an operating system patch.

<a id="impact"></a>

## Impact ##

To say performance hits were noticable on our servers would be an understatement.  This is evident in both server performance metrics and service load times.  I'll break down details of our performance hits during our first steps of canary testing below.

Because of the amount of traffic that we get continuously, there's always non-trivial load against our servers.  When evaluating the performance impact of the patches, I didn't do any synthetic benchmarks.  While synthetic benchmarks can be good to get an understanding of the baseline performance of a system, having real-world performance impact is much more valuable.

### Server Performance Metrics ###

Server performance was immediately visible after patching our test servers.  The most affected and most apparent resource on our patched servers is the CPU.  Increasing load on the CPU however will also increase context switching and waits for other resources--such as network and disk.

#### Web Server Impact ####

This is a bare metal Windows 2012 R2 server running on Dell R630 (13th generation) rack-mount hardware.

Let's take a look at CPU first.  The graph below shows the CPU on one of our front-end web servers before and after the patch.

!!! GRAPH - CPU BEFORE & AFTER !!!

To make sure that this is a fair comparison, let's also take a look at the number of requests being serviced by the web tier.  While this is feeding active public traffic, our load patterns are consistent over time so there is little variance caused by workload changes.

Let's also take a look at some of the other metrics on the system.

!!! GRAPH - MEMORY UTILIZATION !!!

!!! GRAPH - DISK LATENCY !!!

!!! GRAPH - NETWORK UTILIZATION !!!

#### Redis Server Impact ####

This is a bare metal Centos 7 server running on Dell R630 (13th generation) rack-mount hardware.

!!! GRAPH - OPS / sec !!!

!!! GRAPH - CPU !!!

!!! GRAPH - AVERAGE MS / CALL !!!

### User Experience Impact ###

One of the big takeaways here is that the increases in performance metrics didn't linearly translate to longer waits for end users.  That's really good news.  While it's not ideal that we're using significantly more CPU to render a user's request, adding more compute power to our web tier is much easier than cutting down on elapsed time.  Lots of performance tuning has already gone into our codebase, and we're hitting the law of diminishing returns hard.  On the other hand, adding more compute power involves sending Dell some money and racking up some additional servers.

All of the timings below are based on server-side render, which eliminates network connectivity outside of our datacenter to get more accurate numbers.

Here's what happened to our average load times after enabling mitigations:

!!! TABLE - LOAD TIMES & BREAKDOWNS !!!

That said, averages only tell part of the story.  Sets of [100ms, 100ms, 100ms] responses and [20ms, 20ms, and 260ms] responses both have the same average (100ms) but represent much different sets of data.  In addition to averages, we need to keep track of what our least performant requests are doing.

!!! TABLE - LONG TAIL BREAKDOWNS !!!

!!! GRAPH - FLAME GRAPH OF LOAD TIMES !!!

While the redis server referenced above took a huge hit in operation capacity (33% reduction), there is enough overhead in the service that there is virtually no visible impact to end users.

## Takeaways ##

During our testing, we've determined that disabling the fixes in both Windows and Linux restores performance to previous levels.  This makes the process safer to test as it can be quickly restored, but it does require a reboot.  The patch is enabled / disabled in Windows via registry key and Linux via kernel flags at boot.

We're going to continue testing impact on more of our systems so we have a better understanding against different workloads.

### Recommendations ###

Because of the difficulty of exploitation at present and the extreme performance hits involved with implementing these mitigations, teams should carefully weigh whether accepting the performance hits of enabling the mitigations outweighs the risk of leaving the mitigations disabled.  That said, performance impact varies greatly between systems and workloads, so testing the impact against your workloads is recommended.

On servers running trusted and patched software, enabling the mitigations may not be necessary.  Microsoft recommends against enabling the mitigations on SQL Servers that are running on bare metal without CLR enabled.  Other performance-oriented software may also put out similar recommendations going forward.

### Conclusion ###

It's important to remember that system-level performance metrics won't tell the whole story of impact of these mitigations.  Service level metrics, such as page load times, database round trip times, or batch job completion times are much more effective at gauging impact of your systems.  It's not ideal if your flash storage throughput goes to half of what it previously was (i.e. 3 GB/s to 1.5 GB/s), but if you're only sustaining 5 MB/s IO with spikes of 1000 MB/s, the impact will be negligible.  Other changes, such as increased request processing time, can have unexpected consequences.  If requests take longer and volume holds with previous levels, the number of overlapping simultaneous requests increases, which can strain shared resources (such as connection pools to a common back-end service).  Increased CPU utilization also has a direct impact on power consumption; when running your own infrastructure whether colocated or in-house, power constraints may suddenly become a big issue.  As always, make sure to monitor your metrics as you move forward.

### Related Links ###

* <a href="https://meltdownattack.com/" target="_blank" rel="nofollow">Meltdown & Spectre Vulnerability Site</a>
* <a href="https://googleprojectzero.blogspot.co.at/2018/01/reading-privileged-memory-with-side.html" target="_blank" rel="nofollow">Google Project Zero Discovery</a>
* <a href="https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-5754" target="_blank" rel="nofollow">Meltdown CVE</a>
* <a href="https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-5715" target="_blank" rel="nofollow">Spectre (Variant 1) CVE</a>
* <a href="https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-5753" target="_blank" rel="nofollow">Spectre (Variant 2) CVE</a>
* <a href="https://newsroom.intel.com/wp-content/uploads/sites/11/2018/01/Intel-Analysis-of-Speculative-Execution-Side-Channels.pdf" target="_blank" rel="nofollow">Intel Analysis of Meltdown</a>
* <a href="https://support.microsoft.com/en-us/help/4072698/windows-server-guidance-to-protect-against-the-speculative-execution" target="_blank" rel="nofollow">Microsoft Patching Guide for Spectre & Meltdown</a>
* <a href="https://danluu.com/branch-prediction/" target="_blank" rel="nofollow">Explanation of Branch Prediction</a>
