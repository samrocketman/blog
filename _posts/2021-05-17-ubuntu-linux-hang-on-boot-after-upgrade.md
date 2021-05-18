---
layout: post
title: Fixing Ubuntu Linux hang on boot after upgrade
category: gaming
tags:
 - gaming
 - linux
year: 2021
month: 05
day: 17
published: true
type: markdown
---

* TOC
{:toc}

# Scenario

* I have mostly been using my Laptop the past several months.
* After a few months I attempted to boot my Desktop which has Ubuntu 18.04.
* It would hang on boot with the following message.
  ```
  [Done] Started hold until boot process finishes up
  ```

# Attempted fix

I booted into Ubuntu recovery mode successfully via the boot option: advanced
options.  I enabled networking and then connected to a `root` terminal.

First, upgraded packages.

    apt-get update
    apt-get upgrade
    apt-get install <held back packages>

Second, I removed some snaps which appeared to be giving me trouble.

    snap list
    snap remove <package>

I also refreshed the core snaps which basically upgraded them to latest.

    snap refresh

None of it seemed to fix the issue.

# Permanent Fix

After web searching, I realized Wayland may be loaded by GDM.  I found a [good
stack overflow post which addressed fixing the issue][so-fix].  Edit the file
`/etc/gdm3/custom.conf` and uncomment the following line.

```ini
[daemon]
WaylandEnable=false
```

This forced GNOME Desktop Manager 3 to use Xorg instead of Wayland.

# Conclusion

This isn't the first time Wayland has caused me issues.  My opinion is not very
high of it.  I like to play steam games through Proton and other games through
WINE.  However, I seem to always have issues with Wayland even when using
XWayland.

I've been avoiding Ubuntu 20.04 because of Wayland... When Ubuntu 18.04 loses
upgrade support may be the day I stop using Ubuntu unless I can verify gaming
on Linux is stable when I'm ready for the next edition.  I'll probably hold out
for Ubuntu 22.04 and evaluate it for gaming when the time comes.

[so-fix]: https://askubuntu.com/questions/1084550/ubuntu-18-10-stuck-on-started-bpfilter-while-booting/1085596#1085596
