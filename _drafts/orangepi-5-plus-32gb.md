# Orangepi setup

I did several things to set up my orange pi for both some hardening and overall health.

```
apt remove zsh tmux zsh-common
rm -rf /root/.oh-my-zsh
```

Find all listening ports.

    lsof -i -P -n | grep LISTEN

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
    systemctl disable systemd-resolved

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

# Harden orangepi zero 2w

Some extra steps for hardening a small orangepi.

    systemctl disable orangepi-zram-config
    systemctl disable orangepi-ramlog
    systemctl disable systemd-resolved

Ban bad SSH logins

    apt install fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban

Regenerate resolv.conf.

    rm /etc/resolv.conf
    systemctl restart NetworkManager

Add swap, harden memory, and harden temporary filesystems.  2GB temp file space
and 4GB swap memory.

```bash
dd if=/dev/zero of=/tmp2g bs=128M count=16 oflag=dsync status=progress
dd if=/dev/zero of=/swapfile bs=128M count=32 oflag=dsync status=progress
chmod 600 /tmp2g /swapfile
mkfs.ext4 /tmp2g
mount /tmp2g /mnt
chmod 1777 /mnt
umount /mnt
mkswap /swapfile

# configure secured memory on reboot
sed -i '/\/tmp/d' /etc/fstab
echo '/tmp2g /tmp ext4 loop,strictatime,noexec,nodev,nosuid 0 0' >> /etc/fstab
echo '/tmp /var/tmp none bind 0 0' >> /etc/fstab
echo 'tmpfs /dev/shm tmpfs defaults,noexec,nodev,nosuid,seclabel,size=1G 0 0' >> /etc/fstab
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

Reboot and check your mounts.

# Add encypted drives by compiling Linux Kernel

[OrangePI wiki entry for compiling Linux Kernel][compile-wiki]

This is necessary for device-mapper support because dm-mod was not included in
the original OrangePi Ubuntu image.  device-mapper is necessary for encrypted
disks.  See [GitHub issue][dm-mod-issue] on the matter.

Before you begin, back up /boot.  This can either be done by tar or dd.

```bash
tar -czf ~/boot.tgz /boot

# Or minimal backup of dtbs
tar -czf ~/dtbs.tgz /boot/dtb
```

For the most part, installed kernels won't interfere with each other in `/boot`
or `/lib/modules`.  However, `/boot/dtb` does get interference from different
kernels so backing up this at a minimum is recommended.

### Prepare Linux config

I used the Ubuntu server image containing Linux 6.1.  This matters because it
changes the branch you would check out from the orangepi Linux kernel sources.

```
git clone https://github.com/orangepi-xunlong/linux-orangepi.git
cd linux-orangepi/
git checkout orange-pi-6.1-rk35xx
cp /boot/config-6.1.43-rockchip-rk3588 arch/arm64/configs/rockchip_linux_defconfig
sed -i 's/.*CONFIG_BLK_DEV_DM.*/CONFIG_BLK_DEV_DM=y/' arch/arm64/configs/rockchip_linux_defconfig
make rockchip_linux_defconfig
```

This will create a `.config` file which can be edited.  Now, you need to
customize the included Linux modules and verify dm-mod and dm-crypt kernel
modules are available.  By default, they are not.

```
make menuconfig
```

And follow this [Linux kernel configuration guide for LUKS support][dm-crypt].
Once `.config` supports devicemapper with dm-crypt you can compile and install
the Linux kernel.

```
make -j10
make modules_install
make install
make dtbs_install INSTALL_DTBS_PATH=/boot/dtb
```

Reboot and `uname -r` should show the new kernel.  Verify you have modules
enabled.

    modinfo dm-mod
    modinfo dm-crypt

I noticed dm-mod is built-in but dm-crypt is simply a module.  So you'll want to
enable it.

    modprobe dm-crypt
    echo dm-crypt >> /etc/modules

You can create and mount encrypted filesystems.

# Managing encrypted drives

On orangepi, I prefer to manually decrypt drives after boot.  I have the
following script in `/root/decrypt.sh`.

```bash
#!/bin/bash

case "$1" in
  open)
    cryptsetup open /dev/nvme0n1p2 encrypted
    if [ -e /dev/mapper/encrypted ]; then
      mount /mnt/secure
    else
      echo 'ERROR: /dev/mapper/encrypted does not exist.' >&2
    fi
    ;;
  close)
    cryptsetup close /dev/mapper/encrypted
    .
    ;;
  *)
    echo 'First are must be: open or close' >&2
    exit 1
    ;;
esac
```

And `/etc/fstab` entries for my NVMe drive where UUIDs are filesystem UUIDs.

```fstab
UUID=deadeade-6999-4fc1-b498-8486258a1335 /mnt/fast ext4 defaults,noatime,errors=remount-ro 0 2
UUID=deadeade-12b9-4405-99fd-619b28914527 /mnt/secure ext4 defaults,noauto,noatime,errors=remount-ro 0 0
```

# Remote automated management of encrypted disks

Create `/etc/crypttab` and add an entry for the encrypted disk.  For example,

```
encrypted /dev/disk/by-uuid/deadeade-8652-4fab-9dfa-bac217514b9e none luks,tries=1,noauto
```

You can manage starting and stopping the encrypted volume with cryptdisks
scripts.

- `cryptdisks_start encrypted` will decrypt and make available the "encrypted"
  disk.
- `cryptdisks_stop encrypted` will close the "encrypted" disk.

Operating over SSH you can set up a `root` user key command in `authorized_keys`
designed to read from stdin.  Here's the script named `decrypt-disks-stdin.sh`:

```bash
#!/bin/bash
# Created by Sam Gleske
# Tue Jan 13 12:57:46 AM EST 2026
# DESCRIPTION
#   Designed for use over ssh with authorized_keys restricted,command.  This
#   script will read the key to decrypt LUKS from stdin through an SSH
#   connection.
set -euo pipefail

stdin_timeout_seconds=10
disk=/dev/nvme0n1p2
name=encrypted
mount=/mnt/secure

# limit input to 100KiB
read_password_from_stdin() {
  timeout "$stdin_timeout_seconds" dd bs=1 count=102400 status=none
}
strip_input() {
  tr -dc -- '[:print:]' | tr -d '\n\0\r'
}

umask 077
key="$(mktemp /dev/shm/tmp.XXXXXXXXXX)"
trap 'echo "exit status ${PIPESTATUS[*]}" >&2; rm -f "$key"' EXIT
echo reading password from stdin >&2
read_password_from_stdin | strip_input > "$key"
echo decrypting "$disk" >&2
cryptsetup open "$disk" "$name" --key-file - < "$key"
echo mount "$mount" >&2
mount "$mount"
```

Add an entry to `/root/.ssh/authorized_keys` executing the above script if a
specific key connects.

```
restrict,command="/root/decrypt-disks-stdin.sh" <algo> <key> <comment>
```

and on a remote client you can create this simple CLI utility to connect over
ssh and pass the decryption keys via stdin.  On my client, this script is named
`decrypt-orangepi-disk.sh`.

```bash
#!/bin/bash
# Created by Sam Gleske
# Tue Jan 13 01:10:15 AM EST 2026

set -euo pipefail

passphrase() {
cat <<'EOF' | gpg -d
-----BEGIN PGP MESSAGE-----
... encrypt your passphrase
-----END PGP MESSAGE-----
EOF
}

private_key() {
cat <<'EOF' | gpg -d
-----BEGIN PGP MESSAGE-----
... encrypt your SSH private key
-----END PGP MESSAGE-----
EOF
}

umask 077
key="$(mktemp)"
trap 'rm -rf "$key"' EXIT
private_key > "$key"
passphrase | ssh -TF /dev/null -i "$key" root@192.168.8.251
```

# Orangepi zero 2w homeassistant

### Before you begin

Verify you don't have a back door (exploit created from allwinner CPU maker).

```bash
# this shouldn't exist
ls /proc/sunxi_debug/sunxi_debug
```

Set up 8GB swap and 2GB secured tmp space discussed above.  You can create an 8GB swap with the following.

```bash
dd if=/dev/zero of=/swapfile bs=32M count=256 oflag=dsync status=progress
chmod 600 /swapfile
mkswap /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

### Installing home assistant

Follow:

* https://github.com/home-assistant/architecture/blob/master/adr/0014-home-assistant-supervised.md
* https://github.com/home-assistant/os-agent
* And prerequisite package installation https://github.com/home-assistant/supervised-installer
* After all package installation is complete reboot and then proceed.

Edit /etc/os-release and change OS decription because of https://github.com/home-assistant/supervised-installer/pull/262/files.  Set new description to

```diff
1c1
< PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
---
> PRETTY_NAME="Orange Pi 1.0.2 Bookworm"
```

Install home-assistant.deb

In the menu choose qemu-arm64 (nothing else really fits well with the allwinner CPU).
journalctl -fu hassio-supervisor

### Enable cgroup v1

Enable cgroup v1 by modifying `/boot/orangepiEnv.txt` with.

```
extraargs=apparmor=1 security=apparmor systemd.unified_cgroup_hierarchy=false systemd.legacy_systemd_cgroup_controller=false
```

### Enable TLS with nginx

Edit `/usr/share/hassio/homeassistant/configuration.yaml` and add

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.0.0.0/8
    - 127.0.0.1
```

Install nginx

    apt install nginx

Generate certificates and create `/etc/nginx/conf.d/homeassistant.conf` with

```conf
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

upstream websocket {
    server 127.0.0.1:8123;
}

server {
    listen              443 ssl;
    server_name         homeassistant;

    ssl_certificate     /etc/nginx/certs/homeassistant.crt;
    ssl_certificate_key /etc/nginx/certs/homeassistant.key;
    location / {
        proxy_pass http://websocket;
        proxy_set_header Host $host;
        proxy_redirect http:// https://;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
```

### Create and enable a firewall

iptables.rules

```iptables
# Generated by iptables-save v1.8.9 (nf_tables) on Wed Aug 21 21:59:49 2024
*filter
:INPUT ACCEPT [0:0]
:INTERNAL - [0:0]
:INTERNAL_allow - [0:0]
:FORWARD DROP [11:688]
:OUTPUT ACCEPT [0:0]
:OUTPUT_allow - [0:0]
:DOCKER - [0:0]
:DOCKER-ISOLATION-STAGE-1 - [0:0]
:DOCKER-ISOLATION-STAGE-2 - [0:0]
:DOCKER-USER - [0:0]

################################################################################
# INPUT chains
################################################################################

-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# block ATT router initiating connection
-A INPUT -s 192.168.1.254 -j DROP

-A INPUT -i lo -j ACCEPT
-A INPUT -j INTERNAL
-A INPUT -s 172.0.0.0/8 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited

# internal network
-A INTERNAL -s 192.168.1.0/24 -g INTERNAL_allow
-A INTERNAL_allow -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT

# Home assistant over HTTP
-A INTERNAL_allow -p tcp -m state --state NEW -m tcp --dport 8123 -j ACCEPT
-A INTERNAL_allow -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
-A INTERNAL_allow -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT

-A INTERNAL_allow -j RETURN

################################################################################
# OUTPUT chains
################################################################################
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
# docker networks
-A OUTPUT -d 172.0.0.0/8 -j ACCEPT
-A OUTPUT -j OUTPUT_allow
-A OUTPUT -j REJECT --reject-with icmp-host-prohibited

# allow list
-A OUTPUT_allow -d 192.168.1.0/24 -j ACCEPT
#allow broadcast
-A OUTPUT_allow -d 255.255.255.255 -j ACCEPT
-A OUTPUT_allow -p udp -m state --state NEW -m udp --dport 53 -j ACCEPT
#Allow NTP
-A OUTPUT_allow -p tcp -m state --state NEW -m tcp --dport 123 -j ACCEPT
-A OUTPUT_allow -p udp -m state --state NEW -m udp --dport 123 -j ACCEPT
#system updates and web traffic
-A OUTPUT_allow -p tcp -m state --state NEW -m multiport --dport 80,443 -j ACCEPT
-A OUTPUT_allow -j RETURN

################################################################################
# FORWARD chains
################################################################################
-A FORWARD -j DOCKER-USER
-A FORWARD -j DOCKER-ISOLATION-STAGE-1
-A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -o docker0 -j DOCKER
-A FORWARD -i docker0 ! -o docker0 -j ACCEPT
-A FORWARD -i docker0 -o docker0 -j ACCEPT
-A FORWARD -o hassio -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -o hassio -j DOCKER
-A FORWARD -i hassio ! -o hassio -j ACCEPT
-A FORWARD -i hassio -o hassio -j ACCEPT
-A DOCKER -d 172.30.32.6/32 ! -i hassio -o hassio -p tcp -m tcp --dport 80 -j ACCEPT
-A DOCKER-ISOLATION-STAGE-1 -i docker0 ! -o docker0 -j DOCKER-ISOLATION-STAGE-2
-A DOCKER-ISOLATION-STAGE-1 -i hassio ! -o hassio -j DOCKER-ISOLATION-STAGE-2
-A DOCKER-ISOLATION-STAGE-1 -j RETURN
-A DOCKER-ISOLATION-STAGE-2 -o docker0 -j DROP
-A DOCKER-ISOLATION-STAGE-2 -o hassio -j DROP
-A DOCKER-ISOLATION-STAGE-2 -j RETURN
-A DOCKER-USER -j RETURN
COMMIT
# Completed on Wed Aug 21 21:59:49 2024
# Generated by iptables-save v1.8.9 (nf_tables) on Wed Aug 21 21:59:49 2024
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:DOCKER - [0:0]
-A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
-A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
-A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
-A POSTROUTING -s 172.30.32.0/23 ! -o hassio -j MASQUERADE
-A POSTROUTING -s 172.30.32.6/32 -d 172.30.32.6/32 -p tcp -m tcp --dport 80 -j MASQUERADE
-A DOCKER -i docker0 -j RETURN
-A DOCKER -i hassio -j RETURN
-A DOCKER ! -i hassio -p tcp -m tcp --dport 4357 -j DNAT --to-destination 172.30.32.6:80
COMMIT
# Completed on Wed Aug 21 21:59:49 2024
```

ip6tables.rules

```iptables
# Generated by ip6tables-save v1.8.9 (nf_tables) on Wed Aug 21 22:17:13 2024
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
:DOCKER - [0:0]
:DOCKER-ISOLATION-STAGE-1 - [0:0]
:DOCKER-ISOLATION-STAGE-2 - [0:0]
:DOCKER-USER - [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A FORWARD -j DOCKER-USER
-A DOCKER-ISOLATION-STAGE-1 -i docker0 ! -o docker0 -j DOCKER-ISOLATION-STAGE-2
-A DOCKER-ISOLATION-STAGE-1 -i hassio ! -o hassio -j DOCKER-ISOLATION-STAGE-2
-A DOCKER-ISOLATION-STAGE-1 -j RETURN
-A DOCKER-ISOLATION-STAGE-2 -o docker0 -j DROP
-A DOCKER-ISOLATION-STAGE-2 -o hassio -j DROP
-A DOCKER-ISOLATION-STAGE-2 -j RETURN
-A DOCKER-USER -j RETURN
COMMIT
# Completed on Wed Aug 21 22:17:13 2024
# Generated by ip6tables-save v1.8.9 (nf_tables) on Wed Aug 21 22:17:13 2024
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:DOCKER - [0:0]
COMMIT
# Completed on Wed Aug 21 22:17:13 2024
```

[compile-wiki]: http://www.orangepi.org/orangepiwiki/index.php/Orange_Pi_5_Plus#Linux_Development_Manual
[dm-crypt]: https://wiki.gentoo.org/wiki/Dm-crypt
[dm-mod-issue]: https://github.com/orangepi-xunlong/orangepi-build/issues/167
