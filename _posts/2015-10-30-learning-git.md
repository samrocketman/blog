---
layout: post
title: Learning Git
category: education
tags:
 - git
 - programming
year: 2015
month: 10
day: 30
published: true
---

I've found myself recently answering how to learn Git (or specifically how I
learned Git).  This post is for anybody who might be interested and it serves as
a link of resources for myself.

I basically referred to the following educational resources starting out.

* TOC
{:toc}

# Learn the basics

* [Learn git by doing][git-try] or, if you prefer to lay back with your ebook
  reader, check out the free [Pro Git book][git-book].

Learning the basics by following the above instructions helps to prime you for
moving on and learning about more advanced topics of Git.  In order to
understand any complicated problem or tool, if you don't have the basics down
then you'll find it more difficult when tackling advanced topics.

##### Use it often

Use Git as often as you can.  Any time you're working with plain text files you
should make use of Git as a habit.  It's real easy to simply:

{% highlight bash %}
git init
git add -A
git commit -m 'initial commit'
{% endhighlight %}

Then as you work on your project, regularly commit your changes by making use of
`git add` and `git commit`.

##### Learn about workflows

* Learn about workflows: [gitflow][gitflow], [GitLab flow][gitlab-flow], and
  [other types of workflows][git-workflows].  Many teams use a mix of those
  defined workflows.

Workflows are a simple concept of, "how do I work."  There are many strategies
one can adopt when using Git.  Any time you're working in a semi-complicated
project that involves either:

1. Releasing software.
2. Working with more than one person.

You should probably adopt a workflow for yourself.  I tend to adopt workflow
even for projects I work on by myself.  When adopting a workflow it's always
best to adopt it through _social agreement_ rather than putting in technical
controls to force it.  That is, everybody just informally agrees to adopt the
workflow else be willing to be shamed for not adopting it.  If you need
technical controls around how a workflow is adopted, then there is software that
can help.  [Gerrit][gerrit-protect], [GitHub][github-protect], and
[GitLab][gitlab-protect] offer solutions to protect branches.  Gerrit offers the
most advanced access controls around forcing a particular workflow.

> Here's an interesting workflow of how the [Pro Git][git-book] book was
> written: [Living the future of Technical Writing][git-book-workflow]

##### Learn branching

* [Learn git branching](http://pcottle.github.io/learnGitBranching/).

Branches are nice for local and team development.  They can be used for code
review as part of a development workflow.  It's easy to branch off for an
experiment and merge back if your proof of concept is valid.

# Advanced Learning

Once you've learned the basics, workflows, and branching you might want to
tackle more advanced topics when learning Git.  I found these links to videos
helpful and I also include a video _I produced_.

* [Advanced Git Training](http://youtu.be/x2VbPiNJjpw) (video) disclaimer this
  was recorded by me.  A knowledge gap talk, which bridges a git beginner to
  becoming an expert.
* [Git from the bits up](https://www.youtube.com/watch?v=MYP56QJpDr4) an
  advanced talk on Git internals and how it works.
* [Advanced Git Tutorial](https://www.youtube.com/watch?v=8ET_gl1qAZ0) by Linus
  Torvalds, the inventor of Git.

##### Reading documentation

* Read the documentation first and search the Internet as a fallback.

It's always better to read the `man` pages (i.e. manual pages) before attempting
to search for it on the Internet.  There's several reasons to read the man pages
before turning to the Internet.  Some reasons include:

* You become more familiar with the tool documentation.
* You read the documentation which was explicitly written for the version of the
  tool in which you're working.
* Increase your own understanding of self-drafted solutions which can be
  succinct.

Occasionally, help you find on the Internet doesn't work for the version of Git
you're working with.  Primarily because the person providing the help is using
options that aren't available in your (likely older) version.  Here's some
examples of how to read documentation from the terminal.

{% highlight bash %}
git help
git help push
git help clone
{% endhighlight %}

You can also access those same man pages using the `man` command and prefixing
each help page with `git-`.  For example,

{% highlight bash %}
man git-push
man git-clone
{% endhighlight %}

Nearly every command you _could use_ with git has an associated man page.  Take
advantage of that!  `man` is used to read manuals and `apropose` is used to
search them.  If you've not learned how to read man pages before then Internet
search, "how to read man pages."

I enjoy taking man pages and reading them on my ebook reader.  I [wrote a
script][man2pdf] which converts man pages to PDF for portable reading.  Here's
a few examples of taking a Git manual pages and converting them to PDF.

{% highlight bash %}
./man2pdf git-push
./man2pdf git-clone
./man2pdf git-config
{% endhighlight %}

# Teach Git

By teaching Git to others you'll find your own understanding is drastically
improved.  In order to explain to others, you must first comprehend yourself.
The process of you comprehending and explaining improves your ability to work
with Git to know the right solution on your own when you encounter problems.

Happy hacking!

[gerrit-protect]: https://gerrit-documentation.storage.googleapis.com/Documentation/2.11.4/access-control.html
[git-book-workflow]: https://medium.com/@chacon/living-the-future-of-technical-writing-2f368bd0a272
[git-book]: http://git-scm.com/book
[git-try]: http://try.github.com/
[git-workflows]: https://www.atlassian.com/git/workflows
[gitflow]: http://nvie.com/posts/a-successful-git-branching-model/
[github-protect]: https://github.com/blog/2051-protected-branches-and-required-status-checks
[gitlab-flow]: https://about.gitlab.com/2014/09/29/gitlab-flow/
[gitlab-protect]: https://about.gitlab.com/2014/11/26/keeping-your-code-protected/
[man2pdf]: https://github.com/samrocketman/home/blob/master/bin/man2pdf
