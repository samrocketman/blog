---
layout: post
title: "Linux Firewall: A primer for beginners"
category: engineering
tags:
 - programming
 - python
 - shell
 - tips
year: 2019
month: 12
day: 04
published: true
type: markdown
---

* TOC
{:toc}

`iptables` is the firewall built into the Linux kernel.  Since most modern
enterprise Linux distributions use `iptables` I decided to write a primer.  This
guide will walk you through different features of iptables and how to configure
an initial default sane firewall.  In this post I use the words `iptables` and
`firewall` interchangeably but I mean the same thing.  The firewall that is
restricting network traffic in the Linux kernel.

Network Traffic Forwarding typically involves [Network Address Translation][nat]
(NAT) or port forwarding.  This will not be covered in this primer.

> **Side note:** It's worth noting that Linux networking is moving toward
> [`nftables`][nftables] as a replacement but it's not widely deployed amongst
> enterprises, yet.  So I'll just note `nftables` for now so the reader can
> research it if desired.  I may write a followup guide on `nftables` at a later
> date when enterprise adoption becomes more prominent.

# Audience

This guide is intended for individuals who are learning about Linux system
administration, have a grasp on local networking, and have a grasp on Internet
networking concepts.

This guide assumes the audience has the following skills:

* Basic knowledge of Linux system administration.
* Basic knowledge of the Linux Kernel.
* Basic knowledge of networking protocols TCP, UDP, and ICMP.
* Knowledge of internet networking and how subnets are configured.

# Background reading

Read the manuals for

* [iptables][man-iptables]
* [iptables-extensions][man-iptables-x]

# A basic default firewall

Linux distributions typically come with no firewall configured.  So if you don't
enable this yourself, then your Linux machine will generally be unprotected from
network traffic.

The following is a basic iptables firewall that can be applied on any Linux
Desktop system and provide it some minimal security.

```bash
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT

*filter
:FORWARD ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:LOGGING - [0:0]
:OUTPUT ACCEPT [0:0]

# logging rule (use dmesg command to see block logs)
-A LOGGING -m limit --limit 1/second -j LOG --log-prefix "iptables DROP: " --log-level 4

# forwarding rules (block by default)
-A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
-A FORWARD -j LOGGING
-A FORWARD -j REJECT --reject-with icmp-host-prohibited

# inbound traffic rules (block by default)
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -j LOGGING
-A INPUT -j REJECT --reject-with icmp-host-prohibited

# outbound traffic rules (block by default)
#-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#-A OUTPUT -j LOGGING
#-A OUTPUT -j REJECT --reject-with icmp-host-prohibited

COMMIT
```

Apply the firewall with the following command where the above firewall is inside
of a file named `iptables.rules`.

    sudo iptables-restore < iptables.rules

Disable the firewall with the following command.  By default iptables operates
on the `filter` table so you must specify the `nat` table separately to flush
its rules.

    sudo iptables -F
    sudo iptables -t nat -F

### Tables

A firewall is comprised of tables.  A table contains chains.  Chains contain
rules.

There's two firewall tables defined.

- `nat` table is for network address translation and traffic forwarding.  This
  will not be covered.
- `filter` table is for allowing or blocking network traffic ("filter" the
  traffic) which is analagous to most consumer firewalls which have a basic
  concept of allowing or blocking traffic.

### Chains

Chains are sets of related rules inside of `iptables` tables.  Rules restrict
traffic (block, allow, log, etc).

There are three default chains in iptables.  `INPUT`, `OUTPUT`, and `FORWARD`.
Any extra chains defined are custom chains.

- `INPUT` governs inbound traffic (i.e. computers connecting to your machine).
- `OUTPUT` governs outbound traffic (i.e. your machine connecting to others).
- `FORWARD` governs NAT and port forwarding traffic.  Internet routers and
  gateways would typically use this chain.

> **Side note:** iptables also has a `LOG` chain which you don't need to define.
> In the basic firewall above, I defined a custom chain named `LOGGING` which
> will jump traffic to the `LOG` chain so that traffic blocking shows up in
> kernel logs.

Because `:OUTPUT ACCEPT [0:0]` is in the chains defined; output traffic will be
allowed by default.  This is configurable to deny by default but for this
article all chains will allow by default and have explicit rules to block.  All
chains have this same format of `:CHAIN_NAME <default behavior> [<metrics>]`.
Since firewall metrics are a more advanced topic they will not be discussed in
this primer.

### Rules

Rules are grouped under chains.  Rules determine if traffic should be accepted
or rejected based on their source or destination (depending if inbound or
outbound).

Some key points about the basic default firewall above:

- Inbound traffic is blocked by default.  However, established and related TCP
  traffic is allowed.
- Outbound traffic is unrestricted.  Note that the lines start with a pound
  symbol (`#`) which means this is a firewall comment and not applied to the
  firewall as a rule.  Because there's no rules in the `OUTPUT` chain and
- Forwarding traffic is blocked by default as well.

Explaining the state rule: A single session from a web browser on a Linux
workstation will pass through the firewall.

- TCP will establish a connection.  `OUTPUT` chain governs TCP `syn` and
  `syn-ack`.  `INPUT` chain governs TCP `ack`.  During TCP handshacking a
  connection is being `ESTABLISHED`.
- Information is transfered between the server and client.  Client requests get
  sent through `OUTPUT` and server responses come through `INPUT` chain.  All of
  this traffic is `RELATED` to the established TCP session.

# Regional whitelist

It makes sense to support a regional whitelist for personal servers because most
people do not travel outside of their own country often.  The following section
will cover whitelisting the American continent.

> **Side note:** If you're in a country which is located within the same
> regional registry as a hostile nation state that you want to block, then you
> can make use of [ip2location to generate a list specific to
> countries][ip2location] so that you can whitelist your own country
> specifically.  I recommend you download the CIDR list and convert it to
> iptables rules yourself.  The following [GNU awk][gawk] script will convert
> CIDR rules assuming your chain is `MY_NETWORKS` and `MY_NETWORKS_allow`.
>
>     awk '$0 !~ / *#|^$/ { print "-A MY_NETWORKS -s", $0, "-g MY_NETWORKS_allow" }' ~/Downloads/cidr.txt

You can add a regional whitelist to your firewall rules where rules are only
allowed if the traffic is coming from a specific region such as American
continent, Europe, etc.

IPv4 network blocks are split amongst regional registries.  To see which
regional registries have what network blocks refer to the following resources.

- [IANA IPv4 Address Space Registry][ip-blocks-iana]; this list isn't very user
  friendly so refer to wikipedia is also what I recommend.
- [Wikipedia: List of assigned `/8` IPv4 address blocks][ip-blocks-wiki]; which
  includes human readable tables of IP blocks as well as a friendly world map
  for regional registries.

In this example, I'm going to only allow inbound traffic from the registry
[ARIN][arin] which governs traffic for the United States and Canada.

Define a chains for your whitelist:

```bash
:ARIN_NETWORKS - [0:0]
:ARIN_NETWORKS_allow - [0:0]
```

In your `INPUT` table, add a rules to jump to these networks to the top but
below any rules define for local traffic.

```bash
-A INPUT -j ARIN_NETWORKS
```

For your `ARIN_NETWORKS_allow` chain you'll want to add only one rule.  A simple
return rule.

```bash
# Whitelist all American networks.  This doesn't mean the firewall will
# ultimately allow it.  It just means that address will not be automatically
# blocked as a matter of regional policy.
-A ARIN_NETWORKS_allow -j RETURN
```

Finally, you'll want to append rules to the `ARIN_NETWORKS` chain with `-g`
(GOTO statements).  The reason for using `-g` means it will go to the chain, but
the return will jump to the calling chain (`INPUT` chain) instead of returning
to the `ARIN_NETWORKS` chain.

```bash
-A ARIN_NETWORKS -s 3.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 8.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 9.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 13.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 15.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 16.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 18.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 20.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 23.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 24.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 32.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 34.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 35.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 40.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 45.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 47.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 50.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 52.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 54.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 63.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 64.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 65.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 66.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 67.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 68.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 69.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 70.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 71.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 72.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 73.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 74.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 75.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 76.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 96.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 97.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 98.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 99.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 100.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 104.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 107.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 108.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 128.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 129.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 130.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 131.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 132.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 134.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 135.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 136.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 137.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 138.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 139.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 140.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 142.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 143.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 144.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 146.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 147.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 148.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 149.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 152.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 155.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 156.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 157.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 158.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 159.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 160.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 161.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 162.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 164.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 165.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 166.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 167.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 168.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 169.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 170.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 172.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 173.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 174.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 184.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 192.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 198.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 199.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 204.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 205.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 206.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 207.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 208.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 209.0.0.0/8 -g ARIN_NETWORKS_allow
-A ARIN_NETWORKS -s 216.0.0.0/8 -g ARIN_NETWORKS_allow

# reject all traffic not originating from American regional networks.
-A ARIN_NETWORKS -j REJECT
```

The last rule in the `ARIN_NETWORKS` chain will outright drop traffic without
reason (i.e. not send an `ICMP` reason that it was blocked).  This will make it
seem like there is no computer at all.  Traffic will be "lost" from the
perspective of the machine attempting to connect to your server.  It is the last
rule because if any ARIN network addresses match rules, then it will jump
straight to the `ARIN_NETWORKS_allow` chain and not be rejected because of the
regional rule.

Blocking all other regions is a good way to _significantly_ limit the source of
attacks which can occur on your own computers and networks.  Regional white
listing allows you to travel around your own region and still be able to connect
to your own services.  Block countries and regions where you're unlikely to
travel which is best done via network whitelisting.

[arin]: https://www.arin.net/
[gawk]: https://www.gnu.org/software/gawk/manual/
[ip-blocks-iana]: https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.xhtml
[ip-blocks-wiki]: https://en.wikipedia.org/wiki/List_of_assigned_/8_IPv4_address_blocks
[ip2location]: https://www.ip2location.com/free/visitor-blocker
[man-iptables-x]: https://manpages.ubuntu.com/manpages/bionic/en/man8/iptables-extensions.8.html
[man-iptables]: https://manpages.ubuntu.com/manpages/bionic/en/man8/iptables.8.html
[nat]: https://en.wikipedia.org/wiki/Network_address_translation
[nftables]: https://wiki.nftables.org/
