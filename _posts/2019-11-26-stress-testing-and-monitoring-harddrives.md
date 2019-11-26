---
layout: post
title: Stress testing and monitoring harddrives
category: engineering
tags:
 - tips
year: 2019
month: 11
day: 26
published: true
type: markdown
---

* TOC
{:toc}

# Context of this post

In this blog post, I am responding to a [reddit poster within this reddit
discussion][reddit].  This post is intended for users of Linux on personal
computers who want to play with RAID, drive monitoring, and stress testing
drives purchased online to ensure personal harddrive's maximum lifetime.

# Why do I stress test

I do the following to stress test all new drives I purchase.  The reason why I
stress test is to detect `Early "Infant Mortality" Failure` of a drive.  In
layman's terms, this basically means if your drive doesn't fail somewhat
immediately then it generally does a good job at lasting its lifetime.  This has
been my experience and this experience has also been [documented by
others][backblaze] (backblaze has several good storage write-ups I recommend
them as a regular read).

I can only highlight my personal experience on my personal computers and in
general drives that survive my stress test have lasted me for the lifetime that
I needed them (5 years estimated).  Your experience may differ and it's worth
noting that I have experienced drive failures within the first 3 days of my
stress testing.  When it occurs I just get a replacement of the same model from
the place I bought the drive and say that the drive failed; it's usually no
hassle when I've done it.

# How to stress test

When I mount a drive in Linux I usually start 3 terminals with the following
commands.  Let's say your drive is `/dev/XDD` (note I'm **intentionally** making
this a weird non-existent Linux drive so that someone doesn't accidentally copy
and paste it destroying their own data).

```
# terminal 1
while true; do dd if=/dev/zero of=/dev/XDD bs=1000M; done

#terminal 2
while true; do dd if=/dev/urandom of=/dev/XDD bs=1000M; done

#terminal 3
while true; do dd if=/dev/XDD of=/dev/null bs=1000M; done
```

After 3 days of this stress testing you can go to each terminal and type
`CTRL+C` to cancel the loops so that it stops writing/reading data to the disk.

Notes:

- Note that I reference `/dev/urandom` and not `/dev/random`.  urandom generates
  more data with pseudo randomness consistently whereas /dev/random is much more
  secure with randomness but will not generate data if it does not have enough
  entropy.  So using `/dev/urandom` to get the fastest possible random write
  data rate.
- `while true` is necessary so that it indefinitely loops.  When `dd` fills up
  the disk or finishes reading the disk it will exit.  By being in a loop it
  will restart from the beginning.

I let these three terminals run on my computer for 3 days .  Don't forget to
disable sleep and hibernate so that your computer continuously runs during this
time period.

# Analyzing stress test results and running more drive tests

Install `smartmontools` package.  It provides `smartctl` which can be used to
read the [SMART data][smart] from a drive.

    apt-get install smartmontools

The wikipedia page on [SMART attributes][smart] gives you some hints on failures
you can look for.  This mostly applies to spinning disk HDDs but SSDs have SMART
data as well.

> **Note:** even though your SSD has SMART data it might not be documented with
> the Linux kernel so you could see a lot of "unknown" attributes.  Your option
> for this is to research the manufacturer in the hopes that they publish their
> SMART attributes and what they mean.  However, SSDs will still typically
> report standard SMART attributes like `Reallocated Sectors Count`.

To read the SMART data from your drive run

    smartctl -a /dev/XDD

If it looks good, then run a `short` test.  This should take roughly 1-15
minutes.

    smartctl -t short /dev/XDD

After about 15 minutes run the following and look up the results.

    smartctl -a /dev/XDD

If all looks good, then run the `long` test.  This can take in upwards of 4
hours depending on the hard drive vendor and how through their testing.  It
varies.

    smartctl -t long /dev/XDD

To analyze the results, once again run

    smartclt -a /dev/XDD

New drives should have zero reallocated sectors so if you want to be really
conservative replace it if there's any.  Other errors mentioned on the [SMART
wikipedia page][smart] would also prompt me to replace the drive.  I've had
drives show failure indicators from SMART data and have replaced them.  I have
also had one 7200RPM disk drive mechanically fail entirely within the 3 day
stress test.  Drives which have passed my 3 day stress test have lasted me
several years.  I have had drives fail years later so it's not a guarantee but
it is definitely a good practice.

# How did I configure RAID0

I use RAID0 on my system partition.  For software RAID (of any level) you must
configure a non-raid boot partition.  The non-raid boot partition is responsible
for starting your system up and initializing the RAID disks (1st and 2nd level
boot loader; see [this link to learn more][linux-boot]).

I documented how I configured all of this in Linux via [this post of my
notes][notes].  Since these are personal notes I tend to gloss over technical
stuff that I am highly familiar.  They are also not very well organized since
it's a scratchpad I keep adding to every time I re-install my own computer with
RAID (usually from getting new drives; I can typically fish myself out of a hole
when I dig it with system misconfiguration).  Probably the one I need to
reference if you're going to review my notes is [how to chroot into Linux from a
live disk][chroot] which I do not document in my notes (but just remind myself
to do).

I recommend reading all of my notes before you try it.  It's like building legos
where reading the lego instructions first might make it easier to build since
you understand what needs to be done.

# Detecting disk failures

`walteweiss` asked

> Since you use it, I am interested what do you do to prevent the fail, beside
> the 5 years thing. Do you keep just the system on your drives, or your data
> too? And how many drives do you have?

I'll address these parts a little bit at a time.  How to prevent failures is not
really about preventing them, but more about being proactive in monitoring.

On Linux, to get disk monitoring utilities you install the package
`smartmontools` (in Debian).  This gives you disk troubleshooting utilities such
as `smartctl`.  Another neat thing this provides is automatic monitoring of
SMART data for all drives mounted in your computer.  `smartmontools` will email
you when it detects a potential imminent failure.  Most people do not configure
their computers to send email but if you do then you'll get an email saying
"your drive is about to fail so replace it" kind of message from your own
system.

For this to work, you must configure your system to send email.  Rather than
trying to maintain your own mail server (I don't personally), I would configure
my computer to [send email through gmail by configuring postfix and
sendmail][postfix].

To continuously monitor your hard drives see [this great write up on smart
monitoring with smartmontools][monitor-smart].

There are more thorough monitoring solutions that are open source but probably
not worth mentioning since my intention for this reply is personal computers and
not monitoring many computers (thousands).

> Do you keep just the system on your drives, or your data too?

I usually do not keep sensitive data on my RAID0 drives.  Just software,
operating system, steam games, and cloud-synced data such as dropbox and steam
game saves.  I have separate hard drives for data I really care about.

[backblaze]: https://www.backblaze.com/blog/how-long-do-disk-drives-last/
[chroot]: https://wiki.sabayon.org/index.php?title=HOWTO:_chroot_from_a_LiveCD
[linux-boot]: https://developer.ibm.com/articles/l-linuxboot/
[monitor-smart]: https://blog.shadypixel.com/monitoring-hard-drive-health-on-linux-with-smartmontools/
[notes]: https://gist.github.com/samrocketman/9677ca29e0fbaab8f8e55ebc3039172a#gistcomment-2880328
[postfix]: https://www.linode.com/docs/email/postfix/configure-postfix-to-send-mail-using-gmail-and-google-apps-on-debian-or-ubuntu/
[reddit]: https://www.reddit.com/r/buildapcsales/comments/e0paee/ssd_walmart_hyundai_120gb_ssd_1499/f8kc0ad/?context=8&depth=9
[smart-tests]: https://www.thomas-krenn.com/en/wiki/SMART_tests_with_smartctl
[smart]: https://en.wikipedia.org/wiki/S.M.A.R.T.
