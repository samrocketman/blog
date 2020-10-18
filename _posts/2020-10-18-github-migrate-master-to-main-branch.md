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

This post covers how I migrated all of my GitHub projects from `master` branch
to `main`.

* TOC
{:toc}

# Summary

In my journey of migrating all of my GitHub repositories from their default
branch `master` to use `main` as the default I did the following.

- Total migration time about 8 hours which includes writing this post and
  developing all code discussed herein.
- I have 130 repositories.
- 129 repositories required migrating from `master` to `main`.
- 124 repositories required their default branch settings in GitHub to be
  updated.
- 4 repositories required branch protection settings to be updated.  I did this
  manually.
- 69 of my repositories were sources (not forks from other users or
  organizations).
- 19 repositories required code changes.
  - 9 files related to CI code were changed.
  - 13 files related to markdown documentation were changed.
  - [Additional][blog-changes-1] [files][blog-changes-2] changed for this blog
    because of how I build it.

> **Please note:** I completely broke my website and this blog while migrating.
> Unfortunately, while migrating from master to main the [GitHub pages][pages]
> settings did not take.  When I deleted the master branch on the last step
> everything went down... oops.

# Overview

A full migration will generally take the following steps:

1. Mirroring all GitHub projects as local mirrors.  Initially, I will only
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

# Migration environment

I'm using Linux with GNU utilities and openjdk.  If you're migrating from Mac
then you'll have to change some of the arguments for BSD utilities.

Here's my OS and utilities.

    Ubuntu 18.04.5 LTS
    Linux 5.4.0-42-generic x86_64
    coreutils 8.28-1ubuntu1
    GNU bash, version 4.4.20(1)-release (x86_64-pc-linux-gnu)
    openjdk version "1.8.0_265" 64-Bit

# Locally mirror source GitHub projects

I created [cloneable][cloneable] for backing up my GitHub.  I'm going to use it
in order to clone all projects.

I created a [personal access token][github-token] with `repo` scope and cloned
all projects.  I downloaded and setup cloneable.

```bash
export GITHUB_TOKEN="repo scoped GitHub personal access token"
mkdir -p ~/git/main-migration/mirrors ~/git/main-migration/clones
cd ~/git/main-migration/mirrors/
curl -LO https://github.com/samrocketman/cloneable/releases/download/0.6/cloneable.jar.sha256sum
curl -LO https://github.com/samrocketman/cloneable/releases/download/0.6/cloneable.jar
sha256sum -c cloneable.jar.sha256sum
rm cloneable.jar.sha256sum
```

The `mirrors` directory is where I'll keep all bare mirrors of my code.  These
are not workspaces for editing code.  That's what the `clones` directory is for
and we'll touch on this later.

For now, here's how I mirrored all code using `cloneable.jar`.

```bash
java -jar cloneable.jar -fbuo samrocketman | \
  xargs -P32 -n1 -I{} -- git clone --mirror {}
```

# Clone code where default branch is master

In each bare repository, there's a file named `HEAD`.  The contents of `HEAD`
will be the default branch of the given repository.  So let's go into the
`clones` directory and clone all code from the `mirrors` directory where the
default branch is `master`.

```bash
cd ~/git/main-migration/clones
find ../mirrors -maxdepth 2 -type f -name HEAD -exec grep -Hl refs/heads/master {} + | \
  sed 's/HEAD$//' | \
  xargs -P32 -n1 -I{} -- git clone {}
```

The above commands search all repositories where the default branch is `master`
using `find` and `grep`.  Because it prints the HEAD file I use `sed` to trim
off head and then clone every repository based on its directory.  Cloning local
directories is not often used by git users but here I thought it was most
appropriate because it simplified finding repositories I needed to migrate to
`main` branch as the default branch.

# Migrate code tied to master branch

Some repositories will have source code files tied to the `master` branch such
as CI files.  Typically, CI code files are not more than 2 levels deep in the
repository.  So I'm going to search files that are 2-levels deep.  I'm also
going to exclude the `.git` directory from the source code search.

I performed an initial code search for potential files which would be tied to a
branch name.

```bash
cd ~/git/main-migration/clones
find . -maxdepth 3 -type f | \
  grep -vF '/.git/' | \
  xargs -P32 -n1 -I{} -- grep -lF master {}
```

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

```bash
cd ~/git/main-migration/clones
find . -maxdepth 3 -type f | \
  grep -vF '/.git/' | \
  xargs -P32 -n1 -I{} -- grep -lF master {} | \
  grep -Ff filter-file
```


This produced a list of `9` CI files I needed to edit.  I opened them in `vim`
and changed `master` to `main` in all of them.  I'm not going to create a
commit, yet because I'm going to migrate markdown documentation in some
repositories.

### Migrating Markdown documentation

I searched for markdown files which needed to be inspected.  Unfortunately there
was no way to get around reading each of the 30 files found and editing them by
hand.

```bash
cd ~/git/main-migration/clones
find . -maxdepth 3 -type f | \
  grep -vF '/.git/' | \
  xargs -P32 -n1 -I{} -- grep -lF master {} | \
  grep '\.md$'
```

# Inspect repositories with alternate default branches

Not all of my repositories have their default branch set as `master`.  Because
these might be special cases, I needed to inspect them and ensure migrating
`master` to `main` would not adversely affect them.

I cloned all of the repositories which had a default branch set as `master`, so
it is safe to assume that repositories I haven't cloned do not.  Let's search
with this assumption.

```bash
cd ~/git/main-migration/clones
ls -1d * | xargs -n1 -I{} echo {}.git > ../repos
ls -1d ../mirrors/* | grep -vFf ../repos
```

Which returned the following results:

    ../mirrors/cloneable.jar
    ../mirrors/jervis-api.git
    ../mirrors/proxytester.git

Only two of my repositories did not have their default branch set as `master`.
Upon inspecting their code base, neither will be adversely affected.

> **Important:** I notice that [`jervis-api.git`][jervis-api] has no master
> branch at all.  So before I perform my final `master` to `main` branch
> migration I'll be sure to delete it.

# Committing all migrated code

Now that I'm done migrating code, it was time to commit changes to my local
repository mirrors.  I created a commit message (I'll call it `message` in my
command) so that all of the commits include the same message.

It was useful for me to see which repositories would be getting committed
changes.

```bash
cd ~/git/main-migration/clones
for x in *;do (cd "$x"; git diff --exit-code &> /dev/null || echo "$x"; ); done
```

Finally, it was time for me to make the commits using `../../message` that I
created (in this case it was located in `~/git/main-migration/message`).

```bash
cd ~/git/main-migration/clones
for x in *; do
  (
    cd "$x";
    git diff --exit-code || (
      git add -A;
      git commit -F ../../message;
    );
  );
done
```

The above code was written as a one liner but I indented it in this post for
readability.

### Pushing code back to mirror

I still need to push all of the code back to their respective mirrors located at
`~/git/main-migration/mirrors`.

```bash
cd ~/git/main-migration/clones
for x in *; do (cd "$x"; git push origin master; ); done
```

# Mirror all of my GitHub repositories

I initially only cloned my source repositories because I needed to edit code to
migrate the branch from `master` to `main`.  However, ultimately I want to
migrate all of my repositories including forks.

In this step, I'll clone all of my missing forks using [cloneable][cloneable]
again.  Note the following clonable options `-f` is missing now so forks are not
excluded this time.

    cd ~/git/main-migration/mirrors/
    java -jar cloneable.jar -buo samrocketman | \
      xargs -P32 -n1 -I{} -- git clone --mirror {}

# Push all projects to GitHub main branch

The `master` branch for all of my projects have been updated to be compatible
with `main` branch name.  It is time to push it.  This will be simple using the
[Git refspec][git-refspec].

> **Important:** Remember I don't update [`jervis-api.git`][jervis-api] so I
> remove it before doing my branch update operation.


```bash
cd ~/git/main-migration/mirrors/
rm -rf jervis-api.git
find . -type d -name '*.git' | \
  xargs -P32 -n1 -I{} -- \
  /bin/bash -exc 'cd "{}"; git config remote.origin.mirror false; git push origin refs/heads/master:refs/heads/main'
```

> **Note:** I executed `git config remote.origin.mirror false` in each
> repository before pushing because otherwise Git would have failed with an
> error.  Git does not allow pushing refspecs when a repository is a mirror.
> This was a unique case where we wanted to mirror repositories when cloning but
> do some custom logic when pushing (i.e. not mirror).

# Change default branch to main

For all projects where the default branch is `master`, I wanted to switch the
default branch to `main`.  The only way I could feasibly do this is via GitHub
API so this is going to get a little bit more code heavy than previous examples.

I wrote my own GitHub API client in Groovy within my personal [Jervis][jervis]
project.  So I'll use that and check out a tag for archival purposes.  In
reality you can do this in any programming language I've just been doing a lot
of Groovy programming so it is my go to for heavy GitHub operations.

Clone and setup Jervis.  Please note, this requires OpenJDK 8 or similar Java
version.  I'll be using Git tag `jervis-1.7` and you can [read the documentation
for this API version][jervis-1.7-api].

```bash
cd ~/git/main-migration/
git clone https://github.com/samrocketman/jervis/
cd jervis/
git checkout jervis-1.7
./gradlew console
```

In the Groovy console, I wrote up and ran the following script.  You will need
to change the user name for your own projects.  Paste the following into the
Groovy console.

```groovy
String github_token = 'personal access token with repo scope'
String github_user = 'samrocketman'
Boolean dryRun = true

// set dryRun = false when you want to really make changes.  Otherwise, this
// will just tell you what will be changed without making any repository
// settings updates.

/*
 * Non-variable code; no need to edit beyond this point.
 */
import net.gleske.jervis.remotes.GitHubGraphQL
import net.gleske.jervis.remotes.GitHub
import groovy.json.JsonBuilder

GitHub githubV3 = new GitHub()
githubV3.gh_token = github_token
GitHubGraphQL githubV4 = new GitHubGraphQL()
githubV4.token = github_token
String graphql_query = '''
query RepositoryBranches( $user: String!, $page: String = null) {
  repositoryOwner(login: $user) {
    repositories(first: 100, affiliations: OWNER, after: $page) {
      pageInfo {
        hasNextPage
        endCursor
      }
      repository: nodes {
        nameWithOwner
        name
        isFork
        defaultBranch: defaultBranchRef {
          name
        }
      }
    }
  }
}
'''.trim()
Map graphql_variables = [user: github_user]
Boolean queryAgain = true
Map repositories = [:]
// get all repositories whose default branch is master
while(queryAgain) {
    Map response = githubV4.sendGQL(graphql_query, (graphql_variables as JsonBuilder).toString())
    response = response.data.repositoryOwner.repositories
    repositories += response.repository.findAll {
        it.defaultBranch.name == 'master'
    }.collect {
        [(it.nameWithOwner): it]
    }?.sum() ?: [:]
    queryAgain = response.pageInfo.hasNextPage
    if(queryAgain) {
        graphql_variables.page = response.pageInfo.endCursor
    }
}

// iterate over all repositories and update default branch to main
Map data = [default_branch: 'main']
repositories.each { k, v ->
    println "${dryRun? 'DRYRUN: ' : ''}Changing default branch of ${k} to 'main'."
    data.name = v.name
    if(!dryRun) {
        githubV3.apiFetch(
                "repos/${k}",
                ['X-HTTP-Method-Override': 'PATCH'],
                'POST',
                (data as JsonBuilder).toString())
    }
    println 'Success.'
}
if(repositories) {
    println 'All repositories updated.'
}
else {
    println 'No repositories found with default branch set to master.'
}
```

# Delete master branch for all projects

The last step of the migration is to clean up branches which will no longer be
used.  The following code will delete the `master` branch from every one of my
repositories.  Once again, I'm using a [Git refspec][git-refspec] to delete
branches.

```bash
cd ~/git/main-migration/mirrors/
find . -maxdepth 1 -type d -name '*.git' | \
  xargs -P32 -n1 -I{} -- /bin/bash -exc 'cd "{}"; git push origin +:refs/heads/master'
```

[blog-changes-1]: https://github.com/samrocketman/blog/commit/c64ab3ae20fe8e0da085870b2f699a149f641668
[blog-changes-2]: https://github.com/samrocketman/blog/commit/01e507acc85ac0ae17e124bf3aac2ab1d5863ba3
[cloneable]: https://github.com/samrocketman/cloneable
[git-refspec]: https://git-scm.com/book/en/v2/Git-Internals-The-Refspec
[github-token]: https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token
[jervis-1.7-api]: http://sam.gleske.net/jervis-api/1.7/
[jervis-api]: https://github.com/samrocketman/jervis-api
[jervis]: https://github.com/samrocketman/jervis/
[pages]: https://pages.github.com/
