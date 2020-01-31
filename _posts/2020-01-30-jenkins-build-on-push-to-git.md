---
layout: post
title: "Jenkins: Build on push to Git"
category: engineering
tags:
 - git
 - groovy
 - jenkins
 - job-dsl-plugin
 - programming
 - tips
year: 2020
month: 01
day: 30
published: true
type: markdown
---

- TOC
{:toc}

In this post I discuss build on push to GitHub and build on push to Git.  This
was originally [posted to reddit][reddit].

# Build on push to GitHub

For [GitHub webhooks][webhooks],

### Prerequisites you need

- A service account in GitHub with a [personal access token][token] that has
  [OAuth scopes][scopes] `repo` and `admin:repo_hook`.
- The service account must be an admin on the intended repository for the
  multibranch pipeline.  This is necessary so Jenkins can automatically
  configure webhooks.
- Inbound connectivity or delivering payloads from GitHub to your internal
  Jenkins.  You can achieve this three ways that I know of off hand.

1. A proxy which receives webhook payloads and passes them on to Jenkins without
   exposing Jenkins to GitHub.
2. Allow GitHub to directly communicate with your Jenkins instance.  If you do
this, [GitHub publishes their network addresses][github-networks] so you should
limit access only to GitHub webhook IP addresses.
3. Using a webhook relay service like [https://webhookrelay.com/][relay]

### Process

1. Configure a String credential and note the credential you create.  Set the
   scope to system so that it is not widely available to users.
2. Configure the GitHub plugin in Jenkins to [enable manage
   Hooks][configure-gh-plugin] (link to script console script).  Set credential
   ID to your token credential.
3. Use [GitHub branch source configuration][gh-bs-config] (link to [Job DSL
   script][jdsl-wiki]) on multibranch pipelines.

Additional notes:

- If you're configuring the multibranch job manually, then it will register
  webhooks when you save the job.
- If you're configuring it with Job DSL scripts, then you'll need a [post-job
  system groovy script][post-groovy] to run after Job DSL creates the jobs.

# Build on push to Git

I once managed the [Jenkins infrastructure][gimp-ci] for the [GIMP development
team][gimp].  This system did not use typical webhooks but instead used a
generic push to Git from GitLab to trigger builds.

If you [configure your jobs with the Git plugin][configure-git], then you can
utilize the [Git plugin][git-plugin] feature `notifyCommit` where you make a GET
request to `/git/notifyCommit?url=<url encoded git repository>`.  This will
trigger all multibranch pipelines which use the encoded `git clone` URL to
perform a multibranch Scan.

Let's say you configure a multibranch pipeline job to clone source code from
[https://gitlab.gnome.org/GNOME/gimp][gimp-src].  Then you would configure a
hook in GitLab to call the following URL.

    https://jenkins.example.com/git/notifyCommit?url=https%3A%2F%2Fgitlab.gnome.org%2FGNOME%2Fgimp

It is an okay practice to allow webhooks and periodic scans to ensure that you
don't miss any calls for scanning.

You can also configure [post-receive hooks][git-hook] on classic Git
repositories for push events.

[webhooks]: https://developer.github.com/webhooks/
[reddit]: https://www.reddit.com/r/jenkinsci/comments/ewaqdt/building_on_push/fg20g1q/
[token]: https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line
[scopes]: https://developer.github.com/apps/building-oauth-apps/understanding-scopes-for-oauth-apps/
[github-networks]: https://help.github.com/en/github/authenticating-to-github/about-githubs-ip-addresses
[configure-gh-plugin]: https://github.com/samrocketman/jenkins-bootstrap-shared/blob/f8be25b3b8b5b65e4f187790ee413068930a9a3b/scripts/configure-github-plugin.groovy#L61-L71
[gh-bs-config]: https://github.com/samrocketman/jervis/blob/76d8725b8f315b53eca411019883d0330594ca95/jobs/jenkins_job_multibranch_pipeline.groovy#L44-L60
[jdsl-wiki]: https://github.com/jenkinsci/job-dsl-plugin/wiki
[post-groovy]: https://github.com/samrocketman/jenkins-bootstrap-jervis/blob/30362f082674872e6493f318ba4ad8aba05758b0/configs/job_jervis_config.xml#L83-L89
[gimp-ci]: https://gitlab.gnome.org/World/gimp-ci
[gimp]: https://www.gimp.org/
[configure-git]: https://gitlab.gnome.org/World/gimp-ci/jenkins-dsl/blob/a7ddf27940f3e0445ee0a7a66f830ad8869c27c8/jobs/gimp_multibranch_pipelines.groovy#L23-70
[git-plugin]: https://plugins.jenkins.io/git
[relay]: https://webhookrelay.com/
[gimp-src]: https://gitlab.gnome.org/GNOME/gimp
[git-hook]: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#_code_post_receive_code
