---
layout: post
title: Test infrastructure with goss
category: engineering
tags:
 - tips
 - programming
year: 2017
month: 11
day: 17
published: true
type: markdown
---

`goss` is a simple utility for adding infrastructure tests.  It is easy to use
even for the most pedestrian of test writers.  Some example usage includes:

{% highlight bash %}
$ goss add user jenkins
Adding User to './goss.yaml':

jenkins:
  exists: true
  uid: 999
  gid: 998
  groups:
  - jenkins
  home: /var/lib/jenkins
  shell: /sbin/nologin


$ goss validate
......

Total Duration: 0.003s
Count: 6, Failed: 0, Skipped: 0
{% endhighlight %}

[Learn more about `goss`][goss] or [download it][dl].

# Using it in the real world

I added some `goss` infrastructure tests to my personal project:

- [Adding tests to my `jenkins-bootstrap-shared` project][commit].
- See an [overview of all of my project tests][tyml] and how they're integrated
  with CI.
- [CI testing RPM and DEB installs][ci] in action.

Using `goss` I added 80 infrastructure tests for my software which installs via
RPM.  Developing the tests took in less than 10 minutes.

Most of the time I spent trying to figure out how to effectively run the tests
in CI. Then, I spent a few additional minutes copying the RPM work to DEB. A few
minor test modifications were required because of minor differences installing
across operating systems.  I now have 160 infrastructure tests, testing DEB and
RPM package installs in my personal project.  This took relatively little
effort.

# Bonus round

Here's a couple of one-liners I used to quickly add tests for myself.  I'm not
going to explain them much, but I will link to some documentation if you want to
study them.  Keep in mind, I am already in my test environment with my RPM
package installed before running these commands.

{% highlight bash %}
goss add package jenkins-bootstrap

goss add service jenkins

goss add user jenkins

rpm -q --filesbypkg jenkins-bootstrap | awk '$2 ~ "etc" { print $2 }' | xargs -n1 goss add file

rpm -q --filesbypkg jenkins-bootstrap | awk '$2 ~ "init.groovy.d" { print $2 }' | xargs -n1 goss add file

find /var/lib/jenkins | xargs -n1 goss add file

goss validate
{% endhighlight %}

With the above command `goss validate` checks 100 tests.  For my package
installs, I only wanted to check certain parts of my installed software (like
`/etc` and the path containing `init.groovy.d`).

Here are some links to additional reading material for better understanding of
the one liners.

- [`bash` redirection][man-bash-redir]
- [man `rpm`][man-rpm]
- [GNU `awk` manual][man-awk]
- [man `xargs`][man-xargs]
- [man `find`][man-find]


[ci]: https://travis-ci.org/samrocketman/jenkins-bootstrap-shared/builds/303850794
[commit]: https://github.com/samrocketman/jenkins-bootstrap-shared/commit/7b5e325167b40615b53d2e559347d87041d0bd68
[dl]: https://github.com/aelsabbahy/goss/releases
[goss]: https://github.com/aelsabbahy/goss
[man-awk]: https://www.gnu.org/software/gawk/manual/
[man-bash-redir]: https://www.gnu.org/software/bash/manual/html_node/Basic-Shell-Features.html
[man-find]: http://manpages.ubuntu.com/manpages/xenial/man1/find.1.html
[man-rpm]: http://ftp.rpm.org/max-rpm/rpm.8.html
[man-xargs]: http://manpages.ubuntu.com/manpages/xenial/en/man1/xargs.1.html
[tyml]: https://github.com/samrocketman/jenkins-bootstrap-shared/blob/7b5e325167b40615b53d2e559347d87041d0bd68/.travis.yml
