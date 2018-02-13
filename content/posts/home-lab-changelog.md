---
title: "Home Lab - Changelog"
date: 2018-02-12T19:00:00-05:00
tags: [home lab]
description: "Part 1 of the Home Lab environment buildout covering the hardware selection and build process."
---

This tracks the progression my home lab over time.

### Version 0 ###

The initial home lab that I built out was a pair of dual socket Dell 2950 III servers.  This lasted for a few days as the power consumption and noise was too much to deal with when running in the main part of our house.  Power consumption was about 300 watts per server, and the fans were louder than any other server I've ever used.

##### Hardware #####

* 2x Dell PowerEdge 2950 III Servers
  * 2x Intel Xeon E5345 Quad-Core Processors
  * 16GB (8x2GB) DDR2 Memory
  * 6x 72GB 15K RPM Drives
  * Redundant power supplies
* 1x 8-port unmanaged switch
* Asus N66U Router

#### Version 1 ####

By trading a bit of hardware level redunancy (no redundant power supplies, etc), I was able to get a pair of Dell C1100 servers at a price point only slightly higher than what the 2950s cost.  These provided faster processors and much more of memory per chassis.

##### Hardware #####

* 2x Dell C1100 Servers
  * 2x Intel Xeon E5400 Quad-Core Processors
  * 48GB (12x4GB) DDR3 Memory
  * 2x 1TB Western Digital Red Drives
  * Redundant power supplies
* 1x 8-port unmanaged switch
* Asus N66U Router

#### Version 1.1 ####

I added a Dell Optiplex tower to run vCenter and used some TP-Link EasySmart managed switches for networking.  I could now update the VMware hosts more easily.

* 2x Dell C1100 Servers
  * 2x E5400 Quad-Core Processors
  * 48GB (12x4GB) DDR3 Memory
  * 1x 240GB SSD
  * 2x 1TB Western Digital Red Drives
* 1x Dell Optiplex Tower
  * i3 Dual Core Processor
  * 12GB DDR3 Memory (>8GB Necessary for vCenter)
  * 1TB Hard Drive
* 1x 8-port TP-Link EasySmart switch
* Asus N66U Router

#### Version 1.1 ####

As server prices continued to fall, I grabbed a pair of R710s to replace the C1100s, which gave me more hardware level redunancy, iDRAC enterprise interfaces, and better RAID cards, and reduced noise.  Power consumption was slightly higher than the C1100s when using redundant power supplies, but otherwise was very similar.  I just moved the VMware installs and virtual machines to the new hardware, and off I went.

* 2x Dell R710 Servers
  * 2x Intel Xeon E5530 Quad-Core Processors
  * 72GB (18x4GB) DDR3 Memory
  * 1x 240GB SSD
  * 2x 1TB Western Digital Red Drives
  * Redundant power supplies
  * iDRAC Enterprise
* 1x Dell Optiplex Tower
  * 1x Intel i3 Dual Core Processor
  * 12GB (2x4GB & 2x2GB) DDR3 Memory (>8GB Necessary for vCenter)
  * 1TB Hard Drive
* 1x 8-port TP-Link EasySmart switch
* Asus N66U Router

#### Version 1.2 ####

I replaced the EasySmart with a central Force10 S55 switch and hardwired ethernet to my entertainment centers and home office.  It was designed to be a top-of-rack datacenter switch, so it's very fast, but it was thirsty for power, threw off lots of heat, and was very loud relative to the rest of the lab.  It used much more power than the previous switch.  During the transition, I migrated from using the N66U as the firewall and router, I moved those functions to pfSense and used the N66U only as an access point.  I also swapped the Optiplex tower for a R310 server so that all components could be rack mounted.

* 2x Dell R710 Servers
  * 2x Intel Xeon E5530 Quad-Core Processors
  * 72GB (18x4GB) DDR3 Memory
  * 1x 240GB SSD
  * 2x 1TB Western Digital Red Drives
  * Redundant power supplies
  * iDRAC Enterprise
* 1x Dell R310 Server
  * 1x Intel Xeon X3430 Quad Core Processor
  * 16GB (4x4GB) DDR3 Memory (>8GB Necessary for vCenter)
  * 1TB Hard Drive
* 1x Dell Force10 S55
* 2x pfSense Firewalls (VM)
* Asus N66U Router

### Version 2 ###

This version was a major overhaul: I replaced the two server setup with four: three compute nodes and one storage node.  I moved away from rack servers at this point and used Dell Precision T3600 tower workstations for each of the nodes.  The compute nodes each ran vSphere with vCenter running as a VM that could be migrated within the cluster.  The storage node ran FreeNAS.  Overall power consumption was similar to the previous revision, but I had a lot more compute power and more memory than before.  I also replaced the Asus N66U access point with Ubiquiti Unifi APs.

* 3x Dell Precision T3600 Tower Workstations (Compute):
  * 1x Intel Xeon E5-2660 Processor
  * 64GB (4x 16GB) DDR3 Memory
  * 1x 480GB SSD
  * 1x Nvidia Quadro NVS300 Graphics
* 1x Dell Precision T3600 Tower Workstation (Storage):
  * 1x Intel Xeon E5-2660 Processor
  * 32GB (4x8GB) DDR3 Memory
  * 1x 400GB Intel 750 NVMe
  * 4x 4TB HGST 7200RPM NAS HDDs
* 1x Dell Force10 S55
* 2x pfSense Firewalls (VM)
* 3x Ubiqiuiti Unifi Access Points

### Version 3 ###

[See the details here](/posts/2018/home-v3-lab-hardware/)

This was the largest change of all of the revisions: I moved to three compute nodes, each with local storage and migrated from VMware to Hyper-V for the bare metal hypervisor, and I migrated from a datacenter switch to Ubiquiti products.

* 3x Custom Builds (Compute):
  * Corsair Obsidian 750D Airflow Edition Case
  * 32GB (2x 16GB) DDR4 Memory
  * 1x 250GB Samsung 960 Evo NVMe
  * 1x 480GB SSD
  * 1x 4TB HGST 7200RPM NAS HDDs
  * 1x Intel Quad Port NIC
* 1x Unifi Security Gateway
* 1x Unifi 24 Port Switch
* 3x Unifi Access Points (2x AC-Pro, 1x AC-Lite)
