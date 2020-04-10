---
layout: post
title: "Productivity nag workshop"
category: engineering
tags:
 - git
 - programming
 - tips
year: 2020
month: 04
day: 10
published: true
type: markdown
---

- TOC
{:toc}

# I want my computer to productively yell at me

This workshop is to share how I set my computer  up to yell at me...
productively of coarse.  My scripts are designed to operate both on Mac OS and
Linux (with `espeak` package installed).

# First time setup

You'll need to download all of the scripts used for productivity yelling.  I
have scripts for GitHub pull requests, Jenkins statuses, and just general
yelling.

Add the following environment variables to your `~/.bash_profile` configuration.

```bash
export GITHUB_TOKEN="<your github token with repo scope>"
export PATH="$HOME/bin:$PATH"
export JENKINS_HEADERS_FILE=~/.jenkins-headers.json
```

# Download scripts into your personal bin directory

Source code for scripts being downloaded found at
https://github.com/samrocketman/home/tree/master/bin

```bash
mkdir ~/bin
cd ~/bin
export baseurl=https://raw.githubusercontent.com/samrocketman/home/master/bin
for x in say_job_done.sh jenkins-call-url jenkins_wait_job.sh jenkins_wait_reboot_done.sh jenkins_script_console.sh; do
  curl -Lo ~/bin/"$x" "$baseurl"/"$x"
  chmod 755 ~/bin/"$x"
done
```

# Configure Jenkins authentication

To configure `JENKINS_HEADERS_FILE` to store your credentials set up your
credentials in the following way.

```bash
export JENKINS_USER="<your user>" JENKINS_PASSWORD
read -ersp password: JENKINS_PASSWORD

# authenticate with Jenkins
jenkins-call-url -avvo /dev/null -m HEAD https://<your Jenkins host>/
```

This will store your credentials and session information in
`$JENKINS_HEADERS_FILE` on disk.  Subsequent calls will be re-use the cached
session.

If you need credentials for multiple Jenkins instances what I do is move the
existing file to a backup copy.  Like:

```
mv ~/.jenkins-headers.json ~/.jenkins-heads.<jenkins host>.json
```

When I need to switch Jenkins instances, then I restore the appropriate JSON
file to `$JENKINS_HEADERS_FILE` path.

# Yell at me: some examples

This is a one-liners guide to your computer yelling at you from afar.

Wait for a Jenkins job to complete.  Note: the build URL must be a classic build
URL and not a blue ocean build URL.

```bash
jenkins_wait_job.sh https://<your jenkins instance>/<classic build URL with build number>/
```

Get yelled at after a pull request is ready to be merged (i.e. somebody reviewed
and required PR checks passed).

```bash
github_wait_mergeable.sh "<github pull request web URL>"
```

Get yelled at waiting for Jenkins to become available.

```bash
jenkins_wait_reboot_done.sh https://<jenkins server>/
```

Get yelled at waiting for a website to come back...

```bash
until curl -sfILo /dev/null <website url that normally returns HTTP 200>; do sleep 30;done; say_job_done.sh "Website is back online."
```

Wait for SSH to become available on a remote host.

```bash
until ssh -n user@host true; do sleep 30;done; say_job_done.sh "SSH is ready."
```

Wait for a compilation task to finish on your laptop by initiating the task from
the command line.  Also, report its success or failure audibly.

```bash
mvn clean package && say_job_done.sh success || say_job_done.sh failed
```

These are just some of the ways I make my computer aggressive towards me.  I
like using `say_job_done.sh` script because I made it a british male voice of
the `say` command.  Feel free to adjust this voice to your liking which will
translate to the other scripts as well.

# Additional documentation

If you're on Mac OS X and you want to change the voice being used by
`say_job_done.sh` script, then see the following command for additional voices.

    say -v ?

For additional information see

* https://github.com/samrocketman/home/tree/master/bin#jenkins-productivity-scripts
* https://github.com/samrocketman/home/tree/master/bin#github-productivity-scripts
