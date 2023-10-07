---
layout: post
title: "Breaking down Jenkins pipeline execution by efficiency"
category: engineering
tags:
 - groovy
 - jenkins
 - programming
year: 2023
month: 07
day: 25
published: true
type: markdown
---

* TOC
{:toc}

Administering Jenkins at scale can be a challenge to scale the controller
correctly.  However, part of scaling the controller correctly means you set up
user-executable code in a way that pipeline execution scales well.

As an admin, you can provide shared pipeline libraries for code reuse and
provide your own custom plugins.  Often, you'll want to integrate with 3rd party
services such as Jira, artifact hosting, and other services in ways not
currently supported by the Jenkins community.  This means you'll be writing your
own API clients (or using a 3rd party library).
