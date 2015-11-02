---
layout: post
title: Concurrent programming in Jenkins Job DSL Scripts
category: engineering
tags:
 - groovy
 - jenkins
 - job-dsl-plugin
 - programming
year: 2015
month: 10
day: 30
published: true
---

Today I had given myself a fun exercise.  Make generating Jenkins jobs faster by
using concurrent programming.  This is a speed-up optimization to working serial
code.

This is a bit of an advanced post if one hasn't studied concurrent programming,
Jenkins, Groovy, and [Git][git].  None the less I'm documenting this for myself.
I'll first try to define a few of these terms before getting into the meat of
the post for readers who might not be familiar with those topics.

* TOC
{:toc}

##### Definitions

* [Concurrent programming][ccp] - is the practice of creating programs that make
  use of more than one processing core or thread.  The advantage of working with
  threads is the ability to execute a block of long running code while the
  program is able to continue to work on other things.  That is, it doesn't have
  to wait for the long running code.  It can check on it later.  The process of
  developing programs that do this is commonly known as concurrent programming.
* [Jenkins][jenkins] - is a [continuous integration][ci] server.  It is
  typically used to regularly build software as it is being developed.  I'll
  likely write another post on this topic.
* [Job DSL plugin][job-dsl-plugin] - A Jenkins plugin designed to automate
  creating jobs in Jenkins.  It uses Groovy as its runtime.
* [Groovy][groovy] - is a scripting language which runs on the Java Virtual
  Machine.  It is a scripting language that is built into Jenkins and is used by
  the Job DSL plugin.

I recently read a few links which involve [joining threads][thread-join] and
[thread locking][thread-lock] in groovy.  Thread locking is for creating safe
sections of thread execution when [modifying shared memory][thread-shared].
This inspired me to improve my own code by playing around with threading in
Groovy and Jenkins Job DSL scripts.

# Deciding when concurrent programming is appropriate

Concurrent programming doesn't magically speed up every type of program.  You
have to understand the problem you're solving as well as its bottlenecks.  A few
common bottlenecks include: CPU processing, networking, memory.  The best use
case for concurrent programming is for executing a large number of small,
unrelated, tasks which are self contained.

##### Defining the bottleneck

In the case of the Job DSL scripts the small, unrelated, and self contained task
could include creating Jenkins jobs.  Recently, I've been doing a lot of Job DSL
scripting [generating jobs from GitHub repositories][jervis].  This involves a
lot of network calls to the [GitHub API][gh-api].  The way I'm generating jobs
is by generating one job per branch on a GitHub project.

In this case, the bottleneck is networking.  Take for example, the
[`rails/rails`][rails] project.  It has 38 branches on the project.  32 of those
branches contain enough information to generate Jenkins jobs according to my
method.  In my [Job DSL script][dsl-script], I am making the following network
calls.

* Get project branch list
* For each branch, get a file listing.
* If said branch has a file named `.travis.yml`, then generate a Jenkins job
  based on it (or skip it if required).

If 32 branches are build-able (out of 38 total branches).  That means we can
tally up the number of network calls.

* 1 network call for the project branch list.
* 2 network calls for every build-able branch.  (file listing and read file)
* 1 network call for every non-build-able branch.  (file listing)

The total network calls to generate all Jenkins jobs for the `rails/rails`
project is `71` network calls (`1` project + `2*32` build-able branches + `1*6`
non-build-able branches).

Our bottleneck is the network.

##### Solving based on the bottleneck

Because our bottleneck is network and not CPU bound, we can create a large
number of threads rather than limiting ourselves to the number of cores a system
might have.  Therefore, one way we could solve this is to create one thread per
branch.  Our program flow would then look something like this.

* Get project data (i.e. list branches)
* Create one thread per branch so they all execute concurrently.  Each thread
  will be tasked with getting the file listing for that branch and potentially
  reading the contents of the `.travis.yml` file from that branch.
* Join the threads together to finish the execution of the program serially.

# Threading in Groovy

Let's first flesh out a few concepts for threading in Groovy.

##### My first Groovy thread

Gareth Bowles wrote a nice [Groovy script][thread-join] which shows an example
accomplishing two things: spawning a thread and joining it.  What is interesting
is that threads in Groovy can be spawned and started by passing
[closures][closures].  For example:

{% highlight groovy %}
//serially executed code
Thread thread = Thread.start {
    //concurrently executed code
}
//serially executed code continues while concurrent code executes in the
//background.

//pause program and wait for thread to finish before continuing program
thread.join()
{% endhighlight %}

Because we can pass closures to start threads this means threading in Groovy is
pretty easy!

##### Thread lock

I needed to create a thread `lock` variable.  Which threads can use to "wait in
line" to create Jenkins jobs in the Job DSL script.  Chris Broadfoot wrote a
[nice article][thread-lock] which includes a great example of how to implement a
thread lock with a Thread.  It is making use of a few advanced Groovy concepts:
[calling closures][closures] and modifying an imported class during runtime
using [metaprogramming][meta].  Here's our thread lock:

{% highlight groovy %}
import java.util.concurrent.locks.ReentrantLock
//create a lock for use in threads
ReentrantLock.metaClass.withLock = {
    lock()
    try {
        it()
    }
    finally {
        unlock()
    }
}
def lock = new ReentrantLock()
{% endhighlight %}

Threads can make use of `lock.withLock {}` by protecting sections of code and
forcing it to serially execute amongst all threads.

##### Thread with a lock

Now that I know how to start a thread and know how to implement a thread lock
let's combine the two concepts.

{% highlight groovy %}
import java.util.concurrent.locks.ReentrantLock

//create a lock for use in threads
ReentrantLock.metaClass.withLock = {
    lock()
    try {
        it()
    }
    finally {
        unlock()
    }
}
def lock = new ReentrantLock()

//serially executed code
Thread thread = Thread.start {
    //concurrently executed code
    lock.withLock {
        //serially executed code across all threads
    }
    //concurrently executed code
}
//serially executed code while thread runs in background

//wait for thread to finish before program continues
thread.join()
{% endhighlight %}

In this case, the closure is the `{}` argument following `lock.withLock`.  It is
executed using the `it()` method in the `metaClass.withLock` method definition.
It obtains a `ReentrantLock.lock()` to lock the thread, `it()` executes the
closure, and `ReentrantLock.unblock()` releases the lock so another thread can
obtain the lock.  We're doing this to protect a section of the code so that more
than one thread doesn't modify shared memory by forcing it to run serially.

##### Working with multiple threads

Based on the above information I decided the easiest way to work with multiple
threads is to use a `List` of threads.  That basically looks like the following.

{% highlight groovy %}
//Let's say we have a list of tasks to be run
List<Thread> threads = []

//start one thread per task
tasks.each {
    threads << Thread.start {
        //concurrently executed code
    }
}

//wait for each of the tasks to finish
threads.each {
    it.join()
}
{% endhighlight %}

I created a `List` containing every thread.  This means I needed to append an
instance of each thread to the `threads` List.  When I wanted to pause the
program and wait for all threads to finish I simply iterated over the `threads`
list and joined each thread.

# Concurrent Job DSL scripts

Now on to the good stuff.  I've decided that the network is the bottleneck.  I
also gave myself the following constraints.

* Shared memory modification needs to be locked.  Any time shared memory is
  modified, the Job DSL script must be executed serially.
* Network reads can be done concurrently.

Therefore:

* Calls to the GitHub API can be done concurrently because networking is slow.
* Creating Jenkins jobs should be done serially because this can be done
  relatively fast and involves modifying shared memory.

##### Serial Job DSL script

Our goal is to create one thread per branch and then join the threads before
exiting the Job DSL script.  In pseudo code, our program looks like the
following.

{% highlight groovy %}
//get branches
def project = 'github_org/github_project'
def branches = GitHub.branches(project)
//loop over each branch to create jobs
branches.each { branch ->
    def filelist = GitHub.listFiles(project, branch)
    if(!('.travis.yml' in filelist)) {
        //.travis.yml file not found so skip branch
        return
    }
    //.travis.yml file found so get the contents
    def contents = GitHub.getFile(project, branch, '.travis.yml')
    //generate Jenkins job based on the contents
    jenkins.generatJob(contents)
}
{% endhighlight %}

##### Concurrent Job DSL script

I used the threading concepts and solved the problem with the following pseudo
code.

{% highlight groovy %}
import java.util.concurrent.locks.ReentrantLock

//create a lock for use in threads
ReentrantLock.metaClass.withLock = {
    lock()
    try {
        it()
    }
    finally {
        unlock()
    }
}
def lock = new ReentrantLock()

//get branches
def project = 'github_org/github_project'
def branches = GitHub.branches(project)

//list of threads
List<Thread> threads = []

//loop over each branch to create jobs
branches.each { branch ->
    //create one thread per branch
    threads << Thread.start {
        def filelist = GitHub.listFiles(project, branch)
        if(!('.travis.yml' in filelist)) {
            //.travis.yml file not found so skip branch
            return
        }
        //.travis.yml file found so get the contents
        def contents = GitHub.getFile(project, branch, '.travis.yml')

        //force serial execution
        lock.withLock {
            //generate Jenkins job based on the contents
            jenkins.generatJob(contents)
        }
    }
}

//join all threads together
threads.each {
    it.join()
}
{% endhighlight %}

Don't like pseudo code?  Here's [the real code][jervis-threading].

# Conclusion

I enjoy exercises in concurrency and parallelism.  I wasn't solving any real
problems with this post, but I definitely improved the amount of time Jenkins
jobs are created for projects with large amounts of branches.  In fact, the
improvement is so great that there's little difference between generating jobs
for a project with one branch or with many branches (up to an uncertain point).
For me, high performance programming is an itch I occasionally scratch.  I may
or may not make use of this in a production environment in the future.  However,
if I ever need to, then I've already got a proof of concept in this post.  I
find Jenkins quite fascinating because the extensibility in the plugin ecosystem
allows you to do interesting things like this.

Happy Hacking!

[ccp]: http://cs.stackexchange.com/questions/19987/difference-between-parallel-and-concurrent-programming
[ci]: https://en.wikipedia.org/wiki/Continuous_integration
[closures]: http://www.groovy-lang.org/closures.html#_calling_a_closure
[dsl-script]: https://github.com/samrocketman/jervis/blob/master/jobs/firstjob_dsl.groovy
[gh-api]: https://developer.github.com/v3/
[git]: http://sam.gleske.net/blog/education/2015/10/30/learning-git.html
[groovy]: http://www.groovy-lang.org/
[jenkins]: http://jenkins-ci.org/
[jervis]: https://github.com/samrocketman/jervis
[job-dsl-plugin]: https://wiki.jenkins-ci.org/display/JENKINS/Job+DSL+Plugin
[meta]: http://www.groovy-lang.org/metaprogramming.html
[rails]: https://github.com/rails/rails
[thread-join]: https://github.com/jenkinsci/jenkins-scripts/blob/master/scriptler/findOfflineSlaves.groovy
[thread-lock]: http://chrisbroadfoot.id.au/2008/08/06/groovy-threads/
[thread-shared]: http://www.bogotobogo.com/cplusplus/C11/7_C11_Thread_Sharing_Memory.php
[jervis-threading]: https://github.com/samrocketman/jervis/commit/a554a897b5990a9f25450b6908f561d17621cb8f
