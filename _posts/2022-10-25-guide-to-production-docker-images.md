---
layout: post
title: "Guide to production docker images"
category: engineering
tags:
 - programming
 - linux
 - tips
year: 2022
month: 10
day: 25
published: true
type: markdown
---

* TOC
{:toc}

# What makes a good production image

I would like to cover initial basics agnostic to Linux distrobution or
recommended base images.  The intent here is to start by defining what makes a
good Docker image for an application.

- The Docker image should only have dependencies necessary for running the
  application.  This provides a few benefits.
  - Fewer extra software means improved security.
  - A smaller Docker image which means your app or API starts faster in cloud
    provisioning services because it is fast to download.
- The app should log to stdout and stderr.  Not write logs to disk.  This is
  important because Docker can handle log management but not if it is written to
  disk.
- The app should launch in the foreground and manage its own child processes
  from there.  Docker does a good job at process management.  Let Docker manage
  passing signals to your application.
- Even if launched in the foreground, you'll still want the docker image to have
  a process dedicated to PID 1 functions.  If you're not familiar with this
  issue I recommend the original [phusion blog post][pid1] calling out the
  problem.  My preference is to bake in [Yelp dumb-init][dumb-init] for a couple
  of reasons.  dumb-init is small and I don't have to worry about the
  orchestration service supporting `--init` flags for Docker.
  - If not addressing this issue while in production, you'll find that
    occasionally your service will auto-scale.  The auto-scaling could be a
    symptom due to being constrained with resources.  It won't be immediately
    clear without good monitoring and easy to mistake for traffic balancing.
- When your application exits, provide a meaningful exit code.  Zero for success
  and non-zero for failure.  Depending on the complexity of your application it
  might assist troubleshooting if you provide documentation around failure exit
  codes.  The documentation could even include tips on what went wrong and how
  to resolve it such as a run book for a support team.
- Your application should run as a normal user and not root user inside of the
  container.  This improves security of both your app and the host in which it
  resides.
- Your application should start the container with [default Linux
  capabilities][docker-security] provided by Docker.  If possible, try not to
  add any extra capabilities which would reduce the security if your application
  runtime.
- If your app requires outbound network connectivity involving TLS, then it
  should include standard TLS certificate authorities for whatever cloud or
  platform you're working from.
- If your app requires timezone information then you should include Linux
  timezone files.
- Even if you're using a minimal image, you'll want to follow the [Linux
  filesystem hierarchy standard][lfhs] and provide all of the above
  recommendations even if building from scratch.  I will provide an example at
  the end of this article.
- If you add `SHELL ["/bin/sh", "-exc" ]` at the beginning of your `Dockerfile`
  you get better debug output from `/bin/sh` while Docker is building the image.
  This helps narrow down issues to the exact command that fails when a Docker
  build fails.  It also forces a multi-statement `RUN` command to exit with an
  error; without the need to use `&&` between commands.
  - Alternately, if you prefer bash to be you Docker RUN shell you can set
    `SHELL ["/bin/bash", "-exo", "pipefail", "-c" ]`; see bash manual for [the
    set builtin][bash-set].
  - If you only want to debug a single RUN command you can prefix commands with
    `set` instead of changing all RUN shells.  For example, instead of `RUN \`
    within examples, you could remove SHELL and add a single `RUN set -ex; \`.

There are other good practices in general for applications such as integrating
application performance monitoring (APM), unit testing with code coverage,
documentation, and data flow diagrams.  However, this article is mostly
highlighting Docker so I don't plan to dive into these other topics here.  They
are still good to build in as observability will add to service quality.

# An example application

- Flask is a framework based on the current/old standard for Python web
  frameworks: WSGI.
- FastAPI is based on Starlette, which uses the newer standard for asynchronous
  web frameworks: ASGI.

For the purposes of this write-up I developed a simple flask application (a REST
API with only one endpoint from the flask REST API tutorial).  If you're
starting an API from scratch you might want to consider FastAPI, instead.
However, for the purposes of this writeup the application or framework doesn't
matter.  The real star is showing examples of production ready Docker images.

You can go view the example at [docker-production-ready-flask][flask-example].
It follows recommendations from Flask documentation on [how to deploy flask to
production][flask-in-prod] paired with Docker best practices.  The project
README goes into more detail.

# Diving into "from scratch"

Ivan Velichko has a great writeup on, [why Google distroless instead of "from
scratch"][google-distroless]?  The short version of the article is the
following.

`FROM scratch` images are bad (e.g. minimal go apps from scratch) because:

- They can’t run as non-root.
- Timezone information is missing so you will have Go bugs encountered at
  runtime.
- Standard directories (e.g. `/var/tmp` and `/tmp`) are missing which cause
  issues with native Go calls that rely on temporary files.

Let's inspect and verify.  For the purposes of inspection I will pull in a
[statically compiled version of `bash`][static-bash].

Here's our minimal `Dockerfile` for inspection.

```dockerfile
FROM alpine
ADD https://github.com/robxu9/bash-static/releases/download/5.1.016-1.2.3/bash-linux-x86_64 /bash
RUN chmod 755 /bash
FROM scratch
COPY --from=0 /bash /
```

Now to build and look around.

```bash
docker build -t minimal .
```

Launch the container.

```bash
docker run -it --rm minimal /bash
```

Look around.  There's no standard GNU utilities so we'll be limited to shell
built-in functions.

```bash
bash-5.1# echo *
bash dev etc proc sys

bash-5.1# echo dev/* 
dev/console dev/core dev/fd dev/full dev/mqueue dev/null dev/ptmx dev/pts
dev/random dev/shm dev/stderr dev/stdin dev/stdout dev/tty dev/urandom dev/zero

bash-5.1# echo etc/*
etc/hostname etc/hosts etc/mtab etc/resolv.conf

bash-5.1# echo $$
1
```

Some observations:

- It is a minimal container.
- `bash` is our shell and `proc`/`sys` are kernel filesystems so no need to
  inspect them since they are kernel API mounts.
- Because the bash prompt has `#` it means we are running as `root` user.
- We don't need to worry about standard devices or filesystems like `/dev/shm`,
  `/dev/zero`, etc.
- We are missing temporary directories such as `/tmp` and `/var/tmp`.
- We're running as PID 1 (verified with `echo $$`).  Bash can't handle PID 1
  signals.  Any app you put into a from scratch image will also unlikely handle
  signals unless the app is explicitly designed for it.
- `/etc` has standard networking mounts provided by Docker but we don't have
  standard user files like `/etc/passwd` and `/etc/group`.

# Creating our most minimal Docker container

Accounting for best practices (except for TLS certificates and tzinfo)
let's create an example `Dockerfile`.

```dockerfile
ARG base=alpine
FROM ${base}

SHELL ["/bin/sh", "-exc"]
RUN \
  # Prerequisites
  apk add --no-cache build-base; \
  # Directory structure and permissions
  mkdir -p base/bin base/tmp base/var/tmp base/etc base/home/nonroot base/sbin base/root; \
  chmod 700 /root; \
  chown root:root /root; \
  chmod 1777 base/tmp base/var/tmp; \
  chown 65532:65532 base/home/nonroot; \
  chmod 750 base/home/nonroot; \
  # UID and GID
  echo 'root:x:0:' > /base/etc/group; \
  echo 'nonroot:x:65532:' >> /base/etc/group; \
  echo 'root:x:0:0:root:/root:/sbin/nologin' > /base/etc/passwd; \
  echo 'nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin' >> /base/etc/passwd; \
  # init binary for PID 1
  wget -O base/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_"`uname -m`"; \
  chmod 755 base/bin/dumb-init; \
  # nologin binary
  echo 'int main() { return 1; }' > nologin.c; \
  gcc -Os -no-pie -static -std=gnu99 -s -Wall -Werror -o base/sbin/nologin nologin.c; \
  echo "Minimal Container version $VERSION" > /etc/issue


# Add our example program (bash)
# Note: you don't need this for your own application.  In this case static bash
#   is the example application running in user context within a minimal image
# Comment out these lines and update CMD for your own app.
RUN \
  wget -O base/bin/bash https://github.com/robxu9/bash-static/releases/download/5.1.016-1.2.3/bash-linux-"`uname -m`"; \
  chmod 755 base/bin/bash

FROM scratch
COPY --from=0 /base/ /
ENTRYPOINT ["/bin/dumb-init", "--"]
USER nonroot
ENV HOME=/home/nonroot USER=nonroot
WORKDIR /home/nonroot
CMD ["/bin/bash"]
```

Build it.

```bash
docker build -t minimal .
```

Let's look around!

```bash
docker run -it --rm minimal
bash-5.1$

bash-5.1$ echo $$
7

bash-5.1$ /proc/1/exe --version
dumb-init v1.2.5

bash-5.1$ pwd
/home/nonroot

bash-5.1$ while IFS=$'\0' read -r -d $'\0' line; do echo "$line"; done < /proc/self/environ
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=7cdf06c28dd1
TERM=xterm
HOME=/home/nonroot
USER=nonroot

bash-5.1$ echo /sbin/* /bin/* /var/* /t*
/sbin/nologin /bin/bash /bin/dumb-init /var/tmp /tmp

bash-5.1$ cd /; echo *
bin dev etc home proc root sbin sys tmp var

bash-5.1$ echo hello > /tmp/file

bash-5.1$ echo /tmp/*
/tmp/file
```

Observations

- We're running as a normal user because the bash prompt has a dollar sign `$`
  (not root).
- Our shell is no longer PID 1.
- We used the `/proc` kernel file system to verify that PID 1 is the
  [dumb-init][dumb-init] process.  If you're curious about `/proc` you can read
  about it within the [kernel doc `proc.txt`][proc.txt].
- We are in the `nonroot` home directory and our environment reflects the user
  environment.
- We have our binaries in a standard paths.  Following the [Linux filesystem
  hierarchy standard][lfhs].
- `/sbin/nologin` will return non-zero if a user login is attempted.
- As a user, we can write to the `/tmp` filesystem verifying its permissions are
  set correctly along with the sticky bit.

# ARM support

This minimal Docker image is meant to be cross platform for both AMD64 and
ARM64.

    docker buildx build --platform linux/arm64 --build-arg base=arm64v8/alpine -t minimal-arm .

Or if you're on a computer which is already native ARM you can run the original
docker command and it should build just fine.

    docker build -t minimal .

# Full Docker example with TLS CA and tzinfo

I work a lot with Amazon web services.  In my case, it makes sense to copy
certificates and timezone information from `amazonlinux:2`.  However, if you're in
another cloud provider or data center; then use whatever base image of your
choice.  Copying these paths are pretty standard for nearly any Linux
distribution.

```dockerfile
ARG base=alpine
FROM ${base}

SHELL ["/bin/sh", "-exc"]
RUN \
  # Prerequisites
  apk add --no-cache build-base; \
  # Directory structure and permissions
  mkdir -p base/bin base/tmp base/var/tmp base/etc base/home/nonroot base/sbin base/root; \
  chmod 700 /root; \
  chown root:root /root; \
  chmod 1777 base/tmp base/var/tmp; \
  chown 65532:65532 base/home/nonroot; \
  chmod 750 base/home/nonroot; \
  # UID and GID
  echo 'root:x:0:' > /base/etc/group; \
  echo 'nonroot:x:65532:' >> /base/etc/group; \
  echo 'root:x:0:0:root:/root:/sbin/nologin' > /base/etc/passwd; \
  echo 'nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin' >> /base/etc/passwd; \
  # init binary
  wget -O base/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_"`uname -m`"; \
  chmod 755 base/bin/dumb-init; \
  # nologin binary
  echo 'int main() { return 1; }' > nologin.c; \
  gcc -Os -no-pie -static -std=gnu99 -s -Wall -Werror -o base/sbin/nologin nologin.c; \
  echo "Minimal Container version $VERSION" > /etc/issue


# Add our example program (bash)
# Note: you don't need this for your own application.  In this case static bash
#   is the example application running in user context within a minimal image
# Comment out these lines and update CMD for your own app.
RUN \
  wget -O base/bin/bash https://github.com/robxu9/bash-static/releases/download/5.1.016-1.2.3/bash-linux-"`uname -m`"; \
  chmod 755 base/bin/bash

# Pull TLS certifactes and timezone info from amazon
FROM amazonlinux:2
RUN \
  mkdir -p base/etc base/usr/share; \
  cp -r /etc/ssl /etc/pki base/etc/; \
  cp -r /usr/share/zoneinfo base/usr/share/


FROM scratch
COPY --from=0 /base/ /
COPY --from=1 /base/ /
ENTRYPOINT ["/bin/dumb-init", "--"]
USER nonroot
ENV HOME=/home/nonroot USER=nonroot
WORKDIR /home/nonroot
CMD ["/bin/bash"]
```

# Summary

If you're building statically compiled binaries then you can rely on all of the
recommended best practices for Linux and Docker to have both a safer and smaller
Docker image than one provided to you by a Linux distribution.

Here's a small summary of the image sizes.  All sized exclude `bash` assuming
you would remove it to replace it with a statically compiled application.

- `76.4kB` minimal example.  If your app doesn't need CA certificates or
  timezone information then you get all of the security and stability goodies at
  a very small storage price.
- `3.53MB` when including TLS CA certificates and timezone information.

[bash-set]: https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
[docker-security]: https://docs.docker.com/engine/security/
[dumb-init]: https://github.com/Yelp/dumb-init
[flask-example]: https://github.com/samrocketman/docker-production-ready-flask
[flask-in-prod]: https://flask.palletsprojects.com/en/2.2.x/deploying/
[google-distroless]: https://iximiuz.com/en/posts/containers-distroless-images/
[lfhs]: https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard
[pid1]: https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/
[proc.txt]: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/Documentation/filesystems/proc.rst?h=v6.0.3
[static-bash]: https://github.com/robxu9/bash-static/
