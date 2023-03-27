---
layout: post
title: "Securing Jenkins Credentials"
category: engineering
tags:
 - programming
 - linux
 - tips
year: 2022
month: 12
day: 11
published: true
type: markdown
---

* TOC
{:toc}

# Summary

I'm going to cover ways I secure Jenkins credentials.  I've talked at length on
the subject of [Jenkins security and credential storage][script-console] and
written about it in a book I co-authored "Jenkins administrator's guide" on
Amazon.  The best way to manage secrets in Jenkins is to attempt to avoid
storing secrets in Jenkins.  For secrets in pipelines, ensure they're all
time-limited with an expiration to reduce risks around exfiltration.

One way I'll cover is with GitHub App scoped credentials.

# Securing Jenkins credentials

In my years of implementing company-wide process changes for developers across a
few organizations (ranging from small companies with less than 1k employees to
large companies with greater than 100k employees) there's a few things I've
learned about automating processess to balance developer convenience with
security.

In general, a good company-wide solution will:

- Inject appropriate credentials where it makes sense.
- Secure the credentials in a way that credential exposure has limited risk.
- Keep the process as convenient for developers as possible.

There's a lot of needs medium to large sized organizations have when it comes to
delivering software at scale and one of those needs is to have a zero-trust
model when it comes to delivering services.

# Ephemeral Credentials

Static credentials are a risk.  Instead, favoring ephemeral time-limited
credentials is best.  Whether doing a deployment to AWS or another cloud,
releasing artifacts to an artifact store like Nexus, or even pushing commits
back to your own repository.  Credentials could be provided with reasonable
limits.

Here are some useful tips for securing sensitive Jenkins credentials

- Immutable infrastructure and deployment: HashiCorp Vault for SSH CA
  certificates can provide time-limited SSH credentials during image baking with
  Packer.
- Writing commits back to the primary Git repository cloned: you would do this
  in releasing a new version such as pushing a Git tag.  I recommend reviewing a
  [modern Git workflow][glew] for releasing at scale.  For this, I recommend
  relying on GitHub App authentication.  The API credentials

[glew]: https://sam.gleske.net/blog/engineering/2019/11/12/git-low-effort-workflow.html
[script-console]: https://www.youtube.com/watch?v=qaUPESDcsGg
