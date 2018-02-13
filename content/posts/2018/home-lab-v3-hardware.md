---
title: "Home Lab v3 - Part 1: The Hardware"
date: 2018-02-12T20:00:00-05:00
tags: [home lab]
draft: true
description: "Part 1 of the Home Lab environment buildout covering the hardware selection."
---

I do a lot of my development, testing, and infrastructure automation using my home lab.  It gives me a place to try new things with a lot more capacity than my Macbook provides and allows for more hardware customization as well.

If you're curious about the history of my home lab, you can [see the log here](/posts/home-lab-changelog/).

## Goals ##

#### Low Power Consumption ####

I leave my home lab running all of the time.  That means that I don't have to worry about spin-up time when trying to work on projects (which is really nice), but it also means that I need to pay for the electicity to run it continuously (not as nice).  Reducing the power conumed by the lab can be a significant monthly savings in power alone, but it also means less waste heat as well.

#### Performance ####

While my previous nodes performed adequately, when updating the hardware in the lab, I wanted to improve performance - ideally in both overall capacity and single-thread performance.

#### Cost ####

One of the primary goals with the hardware revamp is to save on recurring costs, so keeping cost reasonable for the actual hardware also needs to be taken into account.  This also correlates well with the power consumption goals as the highest end processors (Intel's i9 and high core count Xeon lineups and AMD's Threadripper and Epyc lineups) are both very expensive and consume a lot of power.

#### Resilience ####

I want as few single points of failure as is reasonably attainable.  This very much clashes with the cost and power consumption goals--providing redundant switching requires buying and powering a second switch--and in most of these cases, the decisions favor lower cost and power consumption.  In these cases, I want to make it as easy as possible to replace the single points of failure in the ifrastructure if needed.

## Hardware Selection ##

#### Compute ####

The new compute tier is set up using three compute nodes, each with the following:

* Corsair Obsidian 750D Airflow Edition Case
* Corsair TX-650M Power Supply
* Intel i7-8700K Processor
* Corsair H110i AiO Liquid Cooler
* Asus Z370-A Prime Motherboard
* 32GB (2x16) Crucial Ballistix DDR-4 2400
* 250GB Samsung 960 Evo NVMe (Hyper-V)
* 480GB Crucial MX300 SATA SSD (VMs)
* 4TB HGST 7200RPM NAS HDD (Bulk Data Storage)

_My initial build list was going to use a Corsair Carbide Spec-01 case and H100i v2 cooler, but there wasn't enough vertical clearance for the radiator between the top of the case and the motherboard, so I swapped the case out for the 750D.  Given the increase in size of the 750D, I was able to fit. a 280mm radiator, so I bumped to the H110i._

Currently, the 8700Ks are running at factory clocks, but I wanted to get them over the 8600K for the additional clock speed and hyperthreading and the 8700 for the additional clock speeds and sustained boost speeds.  While the max draw on the 8700K is higher than the other two current Coffee Lake hex-core offerings form Intel, the power draw at idle is comparable to the others.  AMD currently doesn't have anything that performs at the levels of the 8700K (particularly single-thread performance) at similar power consumption.

While the Crucial memory isn't the fastest on the market, it's very reliable--which to me is far more important.  For my lab environment, I don't need ECC in the memory, so I can use a consumer targeted processor with non-ECC memory.

The server configurations have a decent amount of available storage to start, and the 750D case provides tons of room for additional storage - 4x 2.5" trays and 6x 3.5" trays in addition to the two M.2 ports available on the motherboard.  I'll be spanning the available storage across multiple nodes via software to eliminate the single point of failure I had with the FreeNAS server I was running in the previous lab configuration.

#### Networking ####

##### Ubiquiti Unifi Security Gateway & Unifi 24 Port Switch #####

Both the USG and Switch fall under the Ubiquiti umbrella and are managed using the Unifi Controller software, so it can share networks and objects easily between the entire network stack, and they're low power and quiet.  Backing up configurations is easy, and replacing failed hardware is simple.

The USG replaced the previous pfSense failover pair I had running in VMware.  While this worked very well, it had two major issues.  First, it meant that my entire network was dependent on my lab environment for availability.  Second, configuring and updating the failover node was difficult as my ISP only gives me one IP address and therefore only one node can be connected to the internet at any point in time (later pfSense releases removed offline updating).  Using the USG makes management and maintenance much simpler.

## Results ##

From a power consumption perspective, I cut my load from a bit over 400 watts (~80 watts per compute server, ~120 watts for my FreeNAS storage server, and ~60 watts for the switch) to about 160 watts (~45 watts per server and ~25 watts for network equipment).  This should save me about $25 / month at current electricity prices.

The performance jump is significant in every aspect from the previously configured Xeon E5-2660s.  While I lose a few cores (8 -> 6) and some cache, the increases in clock speed more than make up for it in capacity (2.20 -> 3.70 base clock).  The 8700K will push to 4.7GHz stock Turbo Boost, so single core performance is significantly better.

All in, each build cost about $1400 including tax, but I already had an SSD and 4TB HDD for each, so that helped keep the cost down a bit.  This puts the builds into the territory of being able to get a cheaper pre-built computer.  I didn't do that for a few reasons: I wanted control over the components and quality of the build, I didn't need an operating system (Windows licenses are pricey if you need one for a custom build), and I got a better warranty on most components than a manufacturer typically provides.

By having three nodes, I can run clustered services with N+1 redundancy; two nodes can lead to split-brain so a third witness is necessary in most HA clustered scenarios.  This covers the levels of resiliency I'm looking for in my lab.

The build hits all of my goals for my intended use, so I'm happy with the results.  As an added bonus, the builds look really good as well with well routed and out of sight cabling and a clean, black-and-white look.

The next post in the series covers [the build process](/posts/2018/home-lab-build/).
