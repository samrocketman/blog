---
layout: post
title: Migrate GitHub branch master to main
category: engineering
tags:
 - git
 - programming
year: 2020
month: 10
day: 18
published: true
type: markdown
---

This post covers how I migrated all of my GitHub projects from master branch to
main.  It's going to involve:

1. Mirroring all GitHub projects as local mirrors.  In my case, I will only
   include source repositories (not forks).  I'm excluding forks to simplify
   changing code in only repositories I own.  In step 6, I'll mirror my forks
   before updating their branches to main.
2. Clone all local mirrors whose branch matches master.
3. Migrate code tied to master such as CI code.
4. Searching for all projects whose branch does not match master or main to see
   what custom changes need to be done.
5. Commit all of the changes.
6. Mirror all of my repositories.  This is so that my local mirrors include all
   of my repositories (forks and sources) since I finished migrating my code in
   step 5.
7. Push all local mirrors back to GitHub as main branch.
8. For all projects whose default branch is master, switch the default to main.
9. Delete the master branch for every project.

* TOC
{:toc}

# Summary

In my journey of migrating all of my GitHub repositories from their default
branch `master` to use `main` as the default I did the following.

- 69 of my repositories were sources (not forks from other users or
  organizations).
- I had to edit code in some of the repositories.
  - 9 files related to CI code were changed.
  - 13 files related to markdown documentation were changed.
- In total, I migrated 129 repositories under my GitHub user from `master` to
  `main` as the default branch.

# Migration environment

I'm using Linux with GNU utilities and openjdk.  If you're migrating from Mac
then you'll have to change some of the arguments for BSD utilities.

Here's my OS and utilities.

    Ubuntu 18.04.5 LTS
    Linux 5.4.0-42-generic x86_64
    coreutils 8.28-1ubuntu1
    GNU bash, version 4.4.20(1)-release (x86_64-pc-linux-gnu)
    openjdk version "1.8.0_265" 64-Bit

# Locally mirror all GitHub projects.

I created [cloneable][cloneable] for backing up my GitHub.  I'm going to use it
in order to clone all projects.

I created a personal access token with `repo` scope and cloned all projects.  I
downloaded and setup cloneable.

    export GITHUB_TOKEN="repo scoped GitHub personal access token"
    mkdir -p ~/git/main-migration/mirrors ~/git/main-migration/clones
    cd ~/git/main-migration/mirrors/
    curl -LO https://github.com/samrocketman/cloneable/releases/download/0.6/cloneable.jar.sha256sum
    curl -LO https://github.com/samrocketman/cloneable/releases/download/0.6/cloneable.jar
    sha256sum -c cloneable.jar.sha256sum
    rm cloneable.jar.sha256sum

The `mirrors` directory is where I'll keep all bare mirrors of my code.  These
are not workspaces for editing code.  That's what the `clones` directory is for
and we'll touch on this later.

For now, here's how I mirrored all code using `cloneable.jar`.

    java -jar cloneable.jar -fbuo samrocketman | \
      xargs -P16 -n1 -I{} -- git clone --mirror {}

# Clone code where default branch is master

In each bare repository, there's a file named `HEAD`.  The contents of `HEAD`
will be the default branch of the given repository.  So let's go into the
`clones` directory and clone all code from the `mirrors` directory where the
default branch is `master`.

```bash
cd ~/git/main-migration/clones
find ../mirrors -maxdepth 2 -type f -name HEAD -exec grep -Hl refs/heads/master {} + | sed 's/HEAD$//' | xargs -P16 -n1 -I{} -- git clone {}
```

The above commands search all repositories where the default branch is `master`
using `find` and `grep`.  Because it prints the HEAD file I use `sed` to trim
off head and then clone every repository based on its directory.  Cloning local
directories is not often used by git users but here I thought it was most
appropriate because it simplified finding repositories I needed to migrate to
`main` branch as the default branch.

# Migrate code tied to master

Some repositories will have source code files tied to the `master` branch such
as CI files.  Typically, CI code files are not more than 2 levels deep in the
repository.  So I'm going to search files that are 2-levels deep.  I'm also
going to exclude the `.git` directory from the source code search.

I performed an initial code search for potential files which would be tied to a
branch name.

    find . -maxdepth 3 -type f | \
      grep -vF '/.git/' | \
      xargs -P16 -n1 -I{} -- grep -lF master {}

In my case, I came upon several false positives.  Out of `69` repositories I
found `101` files which contained the word `master`.  I manually inspected the
file names and then purposefully picked out the names of CI files I cared about.

The word `master` also showed up in `30` markdown files which is what I use for
documentation in my projects.  I would handle these separately.

So for editing code I split it up into two passes.

1. Edit all CI files updating the branch name to `main`.
2. Edit all documentation referencing the `master` branch and update it to
   `main`.

### Migrating CI code

In my case, the following files were files I knew that were tied to CI systems.
I added the list of files to a grep filter file (I'll call it `filter-file`).

    .travis.yml
    Jenkinsfile
    .jervis.yml
    .azure-pipelines.yml

I reran my find/xargs/grep command but added filtering for the `filter-file` to
it.

    find . -maxdepth 3 -type f | \
      grep -vF '/.git/' | \
      xargs -P16 -n1 -I{} -- grep -lF master {} | \
      grep -Ff filter-file

This produced a list of `9` CI files I needed to edit.  I opened them in `vim`
and changed `master` to `main` in all of them.  I'm not going to create a
commit, yet because I'm going to migrate markdown documentation in some
repositories.

### Migrating Markdown documentation


# Inspect repositories with alternate default branches

Not all of my repositories have their default branch set as `master`.  Because
these might be special cases, I needed to inspect them and ensure migrating
`master` to `main` would not adversely affect them.

I cloned all of the repositories which had a default branch set as `master`, so
it is safe to assume that repositories I haven't cloned do not.  Let's search
with this assumption.

    cd ~/git/main-migration/clones
    ls -1d * | xargs -n1 -I{} echo {}.git > ../repos
    ls -1d ../mirrors/* | grep -vFf ../repos

Which returned the following results:

    ../mirrors/cloneable.jar
    ../mirrors/jervis-api.git
    ../mirrors/proxytester.git

Only two of my repositories did not have their default branch set as `master`.
Upon inspecting their code base, neither will be adversely affected.

> **Important:** I notice that [`jervis-api.git`][jervis-api] has no master
> branch at all.  So before I perform my final `master` to `main` branch
> migration I'll be sure to delete it.

# TODO

document the rest of my migration.  Since I'm writing this mid-migration I want
to publish the post first so that commit messages can include a URL to this blog
post.  I'll update this soon with the rest of the blog post.

[jervis-api]: https://github.com/samrocketman/jervis-api
[cloneable]: https://github.com/samrocketman/cloneable
