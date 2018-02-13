---
title: "Home Lab - Changelog"
date: 2018-02-12T19:00:00-05:00
tags: [home lab]
description: "Part 1 of the Home Lab environment buildout covering the hardware selection and build process."
draft: true
---

This tracks the progression my home lab over time.

### Version 0 ###

The initial home lab that I built out was a pair of dual socket Dell 2950 III servers.  This lasted for a few days as the power consumption and noise was too much to deal with when running in the main part of our house.  Power consumption was about 300 watts per server, and the fans were louder than any other server I've ever used.

### Version 1 ###

By trading a bit of hardware level redunancy (no redundant power supplies, etc), I was able to get a pair of Dell C1100 servers for about what the 2950s cost.  These ran VMware and provided 48GB of memory per chassis.  I used a Dell Optiplex tower to run vCenter and used some TP-Link EasySmart managed switches for networking.  This setup reduced power consumption significantly and added a lot more compute power.

#### Version 1.1 ####

As server prices continued to fall, I grabbed a pair of R710s to replace the C1100s, which gave me more hardware level redunancy, iDRAC enterprise interfaces, and better RAID cards, and reduced noise.  Power consumption was slightly higher than the C1100s when using redundant power supplies, but otherwise was very similar.  I just moved the VMware installs and virtual machines to the new hardware, and off I went.

#### Version 1.2 ####

I replaced the vCenter server with a Dell R310 to mount with the R710s.  Power consumption was slightly higher in the R310 than the previous Optiplex.

### Version 2 ###

This version was a major overhaul: I replaced the two server setup with four: three compute nodes and one storage node.  I moved away from rack servers at this point and used Dell Precision T3600 tower workstations for each of the nodes.  The compute nodes each ran vSphere with vCenter running as a VM that could be migrated within the cluster.  The storage node ran FreeNAS.  Overall power consumption was similar to the previous revision, but I had a lot more compute power and more memory than before.

I also replaced the distributed EasySmart switches with a central Force10 S55 switch.  It was designed to be a top-of-rack datacenter switch, so it's very fast, but it was thirsty for power, threw off lots of heat, and was very loud relative to the rest of the lab.  It used much more power than the previous switches.

### Version 3 ###

This was the largest change of all of the revisions: I moved to three compute nodes, each with local storage and migrated from VMware to Hyper-V for the bare metal hypervisor, and I migrated from a datacenter switch to Ubiquiti products.

[See the details here](/posts/2018/home-lab-hardware/)
