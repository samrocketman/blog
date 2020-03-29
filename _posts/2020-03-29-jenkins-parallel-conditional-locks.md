---
layout: post
title: "Jenkins parallel conditional locks"
category: engineering
tags:
 - git
 - groovy
 - jenkins
 - programming
 - tips
year: 2020
month: 03
day: 29
published: true
type: markdown
---

- TOC
{:toc}

# Reddit question

This blog post is a response to a [question on reddit][reddit].  I ran into the
character limit of reddit while responding so I am converting it to a personal
blog post to share the link.

Here's a quote of the question:

> Sure no problem
>
> ---
>
> Our CI not only builds the product, the product docs and performs unit tests,
> it also performs functional tests. The test matrix is
>
>
> * k8s type: kubeadm, dockeree, openshift3
> * distro: centos or ubuntu
> * Storage backend: ontap fas, soldifire, eseries, cvs
> * Storage protocol: SAN and/or NAS
>
>
> Most of the functional tests run in parallel and the test harness that runs
> them takes at least 30m and most times 1hr. I have a generic function that
> generates the test stage based on metadata in a array of maps.
>
> ---
>
> Most of the tests use private onprem compute(think private cloud), or public
> cloud compute instances. Except for one use case that I'm adding, openshift4
> which we are deploying onprem on baremetal KVM hosts using the
> ocp4_helpernode process
>
> ---
>
> openshift4 is a big crazy config that takes a minimum of 5 machines most of
> which take 4xCore 16GB Ram and because we are using the ocp4_helpernode stuff
> all of them have to be on the same virtual network i.e. that same KVM host.
>
> ---
>
> At any given time there may be one or more jenkins runs in progress that may
> or may not need to test openshift4. i.e. stages are dynamic and are selected
> by coverage tags. pre-merge, nightly etc in the metadata.
>
> ---
>
> I only have so many KVM hosts and if a Jenkins run contains a stage that
> needs to use openshift4, it will need to wait until a hypervisor is free and
> then obtain the lock. When it receives the lock it will execute the entire
> stage.
>
> ---
>
> That use case is only for one type of lock. What happens when I want to lock
> a hypervisor and a storage backend, I'm guessing I would have to do something
> like the following or have a resource name that implies two resources
>
>
> ```
> lock(...) {
>     lock(...) {
>         Do something with both locks
>     }
> }
> ```
>
>
> I actually got the single lock scenario working but I was hoping for
> something that would let me consume the locks in an easier fashion. Something
> like
>
>
> ```
> try {
>     start_lock()
> } catch(Exception e) {
> } finally {
>     clear_lock()
> }
> ```
>
>
> Hope this makes things more clear

Thanks for expanding on your use case.  I think this is the perfect case for
you to use matrix building and conditional locks with a shared pipeline library
step.  I'll try to expand on this with Reddit character limits...

# Assumptions

I assume you're using Jenkins scripted pipeline.  I also assume you have
familiarity with most basic Jenkins pipeline concepts.  If you need
clarification please feel free to ask me followup questions.

# Prerequisites

- Please read documentation on [Jenkins shared pipeline libraries][shared-lib].
  Specifically see the section on `Defining Custom Steps`, because that's what
  I'll be writing here.
- I recently wrote a [Jenkins CI blog post on matrix building][matrix].  Please
  read it.
- In that post, I give a shared pipeline step
  [`getMatrixAxes()`][getMatrixAxes].  Copy this into your own shared library
  so that you can use it.

# Example matrix

The following is a setup similar to what you describe for matrix building.

```groovy
Map matrix_axes = [
    k8s_type: ['kubeadm', 'dockeree', 'openshift3'],
    distro: ['centos', 'ubuntu'],
    storage_backend: ['ontap fas', 'soldifire', 'eseries', 'cvs'],
    storage_protocol: ['SAN', 'NAS']
]

List axes = getMatrixAxes(matrix_axes) { Map axis ->
    // do appropriate conditionals to ensure you only get the product
    // combinations you want
    axis
}
```

This will generate a list of axes which you can then matrix build across nodes
in parallel as outline in [the Jenkins matrix blog post][matrix].

# Defining a conditional lock step

Let's assume you want `openshift3` to be the only thing which is lock limited.

Let's define a shared pipeline conditional lock step based on taking an axis as
input.  In this step, we'll need to support closures so that we can wrap code
inside of the block.

Let's name this step `vars/matrixConditionalLock.groov`.  Now for the source code.

```groovy
// Recursive function that obtains multiple locks at once (or no locks)
def withLocks(List obtain_locks, Closure body) {
    if(obtain_locks) {
        String lockName = obtain_locks.pop()
        lock(lockName) {
            withLocks(obtain_locks, body)
        }
    }
    else {
        body()
    }
}

def call(Map matrix_axis, Closure body) {
    List obtain_locks = []
    if(matrix_axis['k8s_type'] == 'openshift3') {
        obtain_locks << 'openshift3-lock'
    }
    if(matrix_axis['storage_backend'] == 'eseries') {
        obtain_locks << 'eseries-lock'
    }
    // Execute the closure only if all locks have been obtained.  If no locks
    // are requested, then it will execute right away.
    withLocks(obtain_locks, body)
}
```

What this does is obtain a lock only if the `k8s_type` is `openshift3` or if
the `storage_backend` is `eseries`.  What makes this so powerful is you can add
as many lock types as you want.  By using recursion you can create a dynamic
obtaining a lock inside of another lock scenario you originallly described with
the added benefit that it's dynamic and can have many levels deep of locks.

Another benefit of this approach is if you have another `k8s_type` competing
for the same `storage_backend` then the tests will race for the lock and each
of the `k8s_types` will have to wait for the dependent storage backend to be
free.  This means the storage backend will only be available as long as the
lock is free.

For the `k8s_type` `openshift4` it is worth noting that locking on this will
cause all `openshift4` test variants to be forced into serial execution (each
execution racing for the lock before executing.

# Usage in parallel build

Based again on [the Jenkins blog post][matrix] let's execute a parallel build
utilizing the, now created, `matrixConditionalLock` custom step.

```groovy
// assuming List axes is defined like above
Map tasks = [failFast: true]
for(int i = 0; i < axes.size(); i++) {
    // convert the Axis into valid values for withEnv step
    Map axis = axes[i]
    List axisEnv = axis.collect { k, v ->
        "${k}=${v}"
    }

    // define your nodeLabel however you want so that you can execute parallel
    // across Jenkins distributed infrastructure
    String nodeLabel = "k8s_type:${axis['k8s_type']} && distro:${axis['distro']}"

    // stage name is comma separate list of axis values
    String stageName = axisEnv.join(', ')

    // execute code only if conditional lock is obtained
    matrixConditionalLock(axis) {
        node(nodeLabel) {
            checkout scm
            withEnv(axisEnv) {
                sh './scripts/ci-entrypoint.sh'
            }
        }
    }
}
stage("Matrix build") {
    parallel(tasks)
}
```

Please note that I obtain locks outside of the `node` step.  You don't want
your build to hold precious Jenkins nodes while waiting for a lock.

The `./scripts/ci-entrypoint.sh` can use bash conditionals to launch
appropriate testing and harness scripts depending on the matrix axis being
executed.  The following bash environment variables are defined.

```bash
echo "${k8s_type}"
echo "${distro}"
echo "${storage_backend}"
echo "${storage_protocol}"
```

# Summary

Scripted pipeline is extremely powerful.  This solution uses a combination of
programming concepts like recursion and Groovy DSL concepts like passing
closures as method arguments.  This is a little more deep than a typical
Jenkins pipeline but hopefully it helps you gather what you need to do to
accomplish your task at hand.

For additional background reading, see

- Groovy recursion
- [Groovy closures][groovy-closures]
- [Groovy DSL][groovy-dsl] (specifically how it enables DSLs)
- [Groovy Language Specification][groovy-spec]; by reading the full language
  specification (which is a short read) it will enable you to craft more
  advanced pipelines.
- [Jenkins Groovy CPS][jenkins-cps]; Jenkins flavor of Groovy doesn't quite
  support all native Groovy.  Where you see me using strange logic like for
  loops (as opposed to Groovy built-in Collections methods), the root cause is
  usually due to limitations in Jenkins Groovy CPS.  Jenkins provides a
  `@NonCPS` annotation for methods which need to run faster native Groovy but
  this how Jenkins handles Groovy is going to be a blog post I write on its own
  because it's a significant topic.

[getMatrixAxes]: https://github.com/samrocketman/jervis/blob/master/vars/getMatrixAxes.groovy
[groovy-closures]: https://groovy-lang.org/closures.html
[groovy-dsl]: http://docs.groovy-lang.org/docs/latest/html/documentation/core-domain-specific-languages.html
[groovy-spec]: https://groovy-lang.org/documentation.html
[jenkins-cps]: https://github.com/jenkinsci/workflow-cps-plugin/blob/master/README.md#technical-design
[matrix]: https://jenkins.io/blog/2019/12/02/matrix-building-with-scripted-pipeline/
[reddit]: https://www.reddit.com/r/jenkinsci/comments/fp4e8e/resource_locking/
[shared-lib]: https://jenkins.io/doc/book/pipeline/shared-libraries/
