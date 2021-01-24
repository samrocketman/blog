---
layout: post
title: How to publicly expose SSH
category: engineering
tags:
 - linux
 - programming
year: 2021
month: 01
day: 23
published: true
type: markdown
---

I often use SSH remotely as a SOCKS proxy and for port forwarding.  This post
covers how to safely expose SSH from your home network.

* TOC
{:toc}

# Summary

To properly protect your SSH server you'll want to do the following.

- Configure the firewall, fail2ban, and openssh.
- Restrict your firewall to allow IP addresses only from regions where you'll be
  connecting typically.
- Install fail2ban to automatically block suspicious connections.
- Only allow public-key authentication.  On your home private network, you can
  allow passwords but don't ever allow passwords from public networks.
- Port forward SSH to a non-standard port.
