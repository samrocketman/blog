---
layout: post
title: "Securing tmp space"
category: engineering
tags:
 - linux
 - tips
year: 2023
month: 04
day: 29
published: true
type: markdown
---

* TOC
{:toc}

I use Linux as a Desktop and this is one thing (of many) I do to better secure
it for general internet browsing.

# Securing tmp

There's three main temporary files paths in Linux which is standard.

* `/tmp` on disk temp space
* `/var/tmp` on disk temp space
* `/dev/shm` in-memory temp space

These should be secured so that programs cannot be executed from them.  This
prevents a wide array of attacks which assume tmp is capable of executing.
Also, since `/dev/shm` is in-memory it should be limited.  I like to limit it to
at least 1GB or smaller since not a lot of programs use it.  1GB is a safe limit
and it will only take up memory if files are written to it.

# Preparing on-disk tmp

I like to share `/tmp` and `/var/tmp` with the same file system.  This limits
the combination of both spaces.  The following prepares an on-disk image meant
to be used as temporary file storage.  The following commands are executed as
root.

```bash
mkdir /mnt/tmp /root/images

# create a 2GB file-based filesystem
dd of=/root/images/tmp2g if=/dev/zero bs=1024M count=2
mkfs.ext4 /root/images/tmp2g

# change permissions to match /tmp with sticky bit
mount -o loop /root/images/tmp2g /mnt/tmp
chmod 1777 /mnt/tmp
umount /mnt/tmp

# clean up
rmdir /mnt/tmp
```

# Adding fstab entries for boot

With the new file system stored under `/root` we'll be able to mount `/tmp` with
a file system limited to 2GB.  To finish securing temporary files you'll want to
add the following `/etc/fstab` entries.


```
/root/images/tmp2g /tmp ext4 loop,strictatime,noexec,nodev,nosuid 0 0
/tmp /var/tmp none bind 0 0
tmpfs /dev/shm tmpfs defaults,noexec,nodev,nosuid,seclabel,size=1G 0 0
```

A bind mount was created between `/tmp` and `/var/tmp` so they share the same
space-limited filesystem.  Once you reboot, the temporary filesystems will all
be updated (you don't need to reboot but this is the lazy approach).

# Mount options explained

- `loop` will set up a loopback interface.  This treats a file like a device
  (e.g. USB stick).
- `strictatime` It updates the access time each time a file or its cache is
  accessed. This increases the disk writes.
- `noexec` does not allow executables to run (even if their execute bit is set).
- `nodev` character or block devices are not allowed on the file system.
  Examples include `/dev/null`, `/dev/zero`, etc. so devices with similar
  behavior are not allowed in `/tmp`.
- `nosuid` will not honor set-user-ID and set-group-ID bits or file capabilities
  when executing programs from this filesystem.  This may be redundant with
  `noexec` but in general it is a good practice to have this set with `noexec`.
- `defaults` will use the default options: `rw`, `suid`, `dev`, `exec`, `auto`,
  `nouser`, and `async`.
- `seclabel` indicates that the filesystem is using `xattrs` for labels and that
  it supports label changes by setting the `xattrs`.  If you're not using
  SELinux, then this is not necessary.
- `size=1G` will limit the size of the in-memory tmpfs to 1GB.
