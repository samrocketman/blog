# Orangepi setup

I did several things to set up my orange pi for both some hardening and overall health.

```
apt remove zsh tmux zsh-common
rm -rf /root/.oh-my-zsh
```

# Locale, timezone, time

```bash
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
locale-gen en_US en_US.UTF-8
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

echo America/New_York > /etc/timezone
timedatectl set-timezone America/New_York
```

Or if you want a different timezone see `timedatectl list-timezones`.

# delete orangepi user; login as root over ssh

```
ps aux | grep '^orangepi' | awk '{print $2}' | xargs kill -9
deluser orangepi
delgroup orangepi
reboot
rm -f /lib/systemd/system/getty@.service.d/override.conf
find /root -mindepth 1 -maxdepth 1 -exec rm -rf {} +
```

# real time clock battery

    apt remove fake-hwclock

# enable wiregaurd

    modprobe wireguard
    echo wireguard >> /etc/modules

# Disable huaweicloud repositories.

```
sed -i 's/^/#/' /etc/apt/sources.list
```

Add official ubuntu repositories

```
cat >> /etc/apt/sources.list <<'EOF'

#
# Normal Ubuntu ports
#

deb http://ports.ubuntu.com/ubuntu-ports/ jammy main restricted universe multiverse
#deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy main restricted universe multiverse

deb http://ports.ubuntu.com/ubuntu-ports/ jammy-security main restricted universe multiverse
#deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy-security main restricted universe multiverse

deb http://ports.ubuntu.com/ubuntu-ports/ jammy-updates main restricted universe multiverse
#deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy-updates main restricted universe multiverse

deb http://ports.ubuntu.com/ubuntu-ports/ jammy-backports main restricted universe multiverse
#deb-src http://ports.ubuntu.com/ubuntu-ports/ jammy-backports main restricted universe multiverse
EOF
```

Remove unnecessary packages and upgrade:

```
apt remove openvpn libpkcs11-helper1
apt update
apt upgrade
# apt install any held back packages
```

# Install docker for ubuntu

```
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce
systemctl enable docker
```

### Configure logrotate

```bash
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  }
}
EOF
```

# Turn off LEDs on boot

Cron can be used to turn off the LEDs on boot.  I like doing it this way because
later I can script turning on the LEDs for visual notifications.

```bash
cat > /etc/cron.d/turn-off-leds <<'EOF'
@reboot root find /sys -type f -name trigger -path '*/leds/*' -exec /bin/sh -c 'echo none > "{}"' \;
EOF
```

# SystemD configuration

Default for orangepi Ubuntu is graphical.target

    systemctl get-default

To switch OS to headless mode change it to multiuser.

    systemctl set-default multi-user.target

Review startup services and disable what you want.  The following command will
review:

    systemctl list-dependencies multi-user.target

Disable some unnecessary services and targets.

    systemctl disable remote-fs.target
    systemctl disable nfs-client.target
    systectl disable openvpn.service
    systemctl disable dnsmasq.service

# Modify orange pi before boot

If you want to modify the orangepi image before boot you can mount its
filesystem to edit.

Extract the `img` file.

    7za x Orangepi5plus_1.0.8_ubuntu_jammy_server_linux6.1.43.7z

Get the last loop device so you know what to increment.

    lsblk | grep '^loop' | tail -n1

Inspect the partitions

    partx /path/to/Orangepi5plus_1.0.8_ubuntu_jammy_server_linux6.1.43.img
    fdisk -l /path/to/Orangepi5plus_1.0.8_ubuntu_jammy_server_linux6.1.43.img

In my case, `loop75` is the last device so the next one will be `loop76`.
Prepare the devices and partitions for mounting.

    losetup -f /path/to/Orangepi5plus_1.0.8_ubuntu_jammy_server_linux6.1.43.img
    partx -a -v /dev/loop76

Mount the partitions.

    mkdir /mnt/orangepi
    mount /dev/loop76p2 /mnt/orangepi
    mount /dev/loop76p1 /mnt/orangepi/boot

After you're done tear down the image.

    umount /mnt/orangepi/boot
    umount /mnt/orangepi
    losetup -d /dev/loop76

# Writing image to SD card

    dd if=/path/to/file.img of=/dev/mmcblk0 bs=1M oflag=dsync status=progress

`oflag=dsync` forces I/O to match disk speed requiring it to be synchronized.
This means you won't have to worry about uncached writes to the SD card.

`status=progress` gives us a hint of progress.  You can `ls -lh file.img` to
know how large it is so that you have a rough idea when it will complete.

# chroot into SD card

From an x86 machine, it might make sense to chroot into the SD card for editing
configuration files.

Install packages for emulating aarch64 of x86.

    sudo apt-get install qemu binfmt-support qemu-user-static

Plugin the SD card.  In this example, SD card is mounted as
`/media/sam/opi_root`.

    docker run --platform=linux/arm64 -it --rm --privileged -v /media/sam/opi_root:/mnt -w /mnt ubuntu:22.04

Run `arch` to verify you're in the correct CPU architecture (should return
`aarch64`).  And then proceed to chroot into orangepi Ubuntu which is mounted on
`/mnt`.

    mount -o bind /dev /mnt/dev
    mount -o bind /dev/pts /mnt/dev/pts
    mount -o bind /sys /mnt/sys
    mount -o bind /proc /mnt/proc
    cp /etc/resolv.conf /mnt/etc/resolv.conf
    chroot /mnt
