---
title: "Home Lab - Part 2: The Build Process"
date: 2018-02-12T21:00:00-05:00
tags: [home lab]
description: "Part 2 of the Home Lab environment buildout covering the build process for the compute nodes."
draft: true
---

_I've never built a computer before._ I figured now is as good a time as any to give it a shot.  And why not do three while I'm at it for my new home lab.

If you're curious as to why I chose the hardware I did, [see the previous post in the series](/posts/2018/home-lab-hardware/).

## Getting Started ##

First thing I did was plan out my list of hardware (which almost all worked together - all of the components were compatible, but the liquid cooling radiator didn't fit the original case).  I got everything from Micro Center--they had all of the components that I wanted in stock and had solid pricing (most of which was cheaper than online retailers).

<a href="/img/posts/2018/home-lab-build/everything.jpg" class="magnific-popup" title="All of the components">
    <img src="/img/posts/2018/home-lab-build/everything.jpg">
</a>

First thing I did was unpack the case.  I started with a Corsair Carbide Spec-01 case, but realized that while the fan screw pattern is there for a 120x240mm radiator, the motherboard wouldn't clear the H100i radiator that I got.  While it does seem like a nice case for the price, without being able to fit my components, I'd have to choose something else.

<a href="/img/posts/2018/home-lab-build/carbide-spec-01.jpg" class="magnific-popup" title="Corsair Carbide Spec-01">
    <img src="/img/posts/2018/home-lab-build/carbide-spec-01.jpg">
</a>

So I switched the Spec-01 for a Corsair Obsidian 750D Airflow Edition case.  The new case is significantly larger, but it also offers a lot of options for mounting components--lots of room for 140mm fans, lots of hard drives and SSDs, and plenty of room for cable management behind the motherboard.

<a href="/img/posts/2018/home-lab-build/750d.jpg" class="magnific-popup" title="Corsair Obsidian 750D Airflow Edition">
    <img src="/img/posts/2018/home-lab-build/750d.jpg">
</a>

Once unpacked, I installed the power supply.  I made sure to get a modular power supply.  Even though there's lots of room to hide cables in the 750D case, having fewer cables to hide is always a plus.  In the effort of trying to keep this setup as efficient as possible, I went with the 80+ Gold rated TX series power supplies.  The 750D has an intake on the bottom for the power supply, so the power supply fan is installed on the bottom.

<a href="/img/posts/2018/home-lab-build/power-supply.jpg" class="magnific-popup" title="Power Supply Installed">
    <img src="/img/posts/2018/home-lab-build/power-supply.jpg">
</a>

Now that the power supply is installed, the case is ready for the motherboard.  I switched over to that setting up the motherboard.  Prior to installing the motherboard, I installed the CPU and NVMe storage.

From the unboxing, one of the Asus motherboards had a bent audio connector pin.  That was easily bent back into place and wasn't an issue afterward.

Here's the motherboard once unboxed:

<a href="/img/posts/2018/home-lab-build/motherboard.jpg" class="magnific-popup" title="Unboxed Motherboard">
    <img src="/img/posts/2018/home-lab-build/motherboard.jpg">
</a>

Next task is to swap the plastic socket cover for a CPU.  This is dead simple; just line up the arrow on the corner of the processor with the mark on the socket, and latch:

<a href="/img/posts/2018/home-lab-build/cpu-installed.jpg" class="magnific-popup" title="CPU Installed">
    <img src="/img/posts/2018/home-lab-build/cpu-installed.jpg">
</a>

Once the CPU was installed, I installed the NVMe.  I installed it in the slot underneath the heatsync (the other slot is exposed and visible):

<a href="/img/posts/2018/home-lab-build/nvme.jpg" class="magnific-popup" title="NVMe Installed">
    <img src="/img/posts/2018/home-lab-build/nvme.jpg">
</a>

Now the motherboard is ready to be installed:

<a href="/img/posts/2018/home-lab-build/cpu.jpg" class="magnific-popup" title="Motherboard ready for installation">
    <img src="/img/posts/2018/home-lab-build/cpu.jpg">
</a>

Motherboard installation required snapping the back plate into the case and lining the motherboard up with the screw holes on the case:

<a href="/img/posts/2018/home-lab-build/motherboard-installed.jpg" class="magnific-popup" title="Motherboard Installed">
    <img src="/img/posts/2018/home-lab-build/motherboard-installed.jpg">
</a>

Once the motherboard was in place, the CPU cooler could be installed.  I installed it as an exhaust in the top of the case.  I wanted to keep the inside appearance as clean as possible, so rather than looking at fans, I wanted to mount the radiator under the fans.  This was a bit tricky to line up and get the screws installed, but once done, I was very happy with the result:

<a href="/img/posts/2018/home-lab-build/radiator.jpg" class="magnific-popup" title="Radiator Installed">
    <img src="/img/posts/2018/home-lab-build/radiator.jpg">
</a>

After the radiator was installed the cooler could be installed on the CPU.  This part wasn't nearly as difficult as the radiator installation; I just needed to make sure to not make contact between the CPU and the bottom of the socket during installation until I was ready to tighten it down.  The back plate and standoff screws installed first--this could be done either before or after installing the motherboard.  The cooler then attaches to the installed standoff screws.

<a href="/img/posts/2018/home-lab-build/cooler.jpg" class="magnific-popup" title="CPU Cooler Installed">
    <img src="/img/posts/2018/home-lab-build/cooler.jpg">
</a>

Last step was to install memory into the motherboard and tidy up the cabling.  I also installed an Intel PCIe 4-port NIC.  Once complete, the machines were booted for the first time:

<a href="/img/posts/2018/home-lab-build/finished.jpg" class="magnific-popup" title="Build complete">
    <img src="/img/posts/2018/home-lab-build/finished.jpg">
</a>

Stay tuned for Part 3: Infrastructure that will cover the switching setup and base configurations for the systems.
