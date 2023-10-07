---
layout: post
title: "Create a Nexus proxy for downloading GitHub releases"
category: engineering
tags:
 - linux
 - tips
year: 2023
month: 10
day: 06
published: true
type: markdown
---

* TOC
{:toc}

In large environments, it makes sense to cache artifacts locally in-network
where downloads occur frequently.  An example of this is a proxy for CICD
environments performing regular builds.

This guide covers how to configure Sonatype Nexus for downloading releases from
GitHub.  In general, you should only cache items you expect to never change or
wouldn't want to change.

# What to proxy from GitHub

There's three types of GitHub downloads which I think fit this description:

* GitHub releases
* Source code archives downloaded by Git SHA1
* Source code archives downloaded by Git tag

The least reliable of the three types are GitHub releases and Git tag because
open source projects can change these.  The intent of a proxy is to provide
stability in an environment so even if the upstream changes the artifact the
local cache would not change (nor would I want it to).

# Routing rules

[Routing rules][rr] in Nexus restrict what content is allowed to be resolved
from a repository within Nexus.  Because GitHub has standard URLs for
downloading for all projects, you can use a regular experession in a routing
rule.

Routing rule settings:

- **Name**: `GitHubReleases`
- **Description**: `Download GitHub Releases.  Download source code archives via
  Git SHA1 or tag.`
- **Mode**: `Allow` (meaning any requests which do not match regex ar not
  allowed)

Finally, **Matchers** are regular expressions which restrict downloads.  You
only need two matchers.

```
/[^/]+/[^/]+/releases/download/[^/]+/.+

/[^/]+/[^/]+/archive/([0-9a-f]{40}|refs/tags/.+)\.(zip|tar\.gz)
```

The first matcher covers downloading from GitHub releases.  The second matcher
covers downloading archives from Git SHA1 or Git tag; in both, zip or tar.gz
formats.

# Proxying GitHub releases

Nexus has a [raw repository type][rp] which can be configured to proxy URLs.  Here are
its settings.

- **Name**: `github`
- **Content Disposition**: `Attachment`
- **Remote Storage**: `https://github.com`
- **Auto blocking enabled**: enable (my opinion; if there's GitHub outages)
- **Maximum component age**: `-1` (for release artifacts)
- **Maximum metadata age**: `30` (minutes; my opinion)
- **Strict Content Type Validation**: Unchecked i.e. not strict
- Set the **Routing Rule** to the rule created in the previous section.
- **Not found cache enabled**: enable it
- **Not found cache TTL**: `5` (minutes; my opinion)

# How to download

If you did all of this on a local host Nexus then you would prefix the
repository URL with the GitHub URL replacing `github.com` with your Nexus
repository.

Instead of

```
https://github.com/samrocketman/yml-install-files/releases/download/v2.14/universal.tgz
```

You would download

```
http://localhost:8081/repository/github/samrocketman/yml-install-files/releases/download/v2.14/universal.tgz
```

[rp]: https://help.sonatype.com/repomanager3/nexus-repository-administration/formats/raw-repositories
[rr]: https://help.sonatype.com/repomanager3/nexus-repository-administration/repository-management/routing-rules
