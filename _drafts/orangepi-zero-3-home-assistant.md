# Orange Pi Zero3

- [Hardware page][hardware]
- [Software page][software] [Home Assistant Supervised][ha-super] only supports
  Debian 12 Bookworm

# Prepare Debian Linux for hardware

1. Download Linux 6.1 Debian Bookworm Server image from the software page above.
2. Extract the 7z archive.

   ```bash
   7za x Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.7z
   # verify the image checksum before modifying it
   shasum -c Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.img.sha
   ```

3. Write the image to your SD card

   ```bash
   fdisk -l
   # check which drive is your plugged in sdcard
   sudo dd if=Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.img of=/dev/mmcblk0 bs=100M oflag=dsync status=progress
   ```

4. Initial boot and login (this will change after hardening).  Plug into
   ethernet and look at your router homepage for its assigned IP.  There are two
   users with default passwords.  In the hardening section, orangepie will be
   deleted and root password will be changed.

   - User: root, password: orangepi
   - User: orangepi, password: orangepi

5. Log in with SSH

   ```bash
   ssh root@<IP address and use orangepi as password>
   ```

# Hardening operating system

Set hostname

    hostnamectl set-hostname homeassistantzero3

Change password for root assuming you're logged into root already.

    passwd

Delete orangepi user and other unnecessary settings.

```bash
ps aux | grep '^orangepi' | awk '{print $2}' | xargs kill -9
deluser orangepi
delgroup orangepi
reboot
rm -f /lib/systemd/system/getty@.service.d/override.conf
find /root -mindepth 1 -maxdepth 1 -exec rm -rf {} +
```

Update locale and timezone (change from China to US).

```bash
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
locale-gen en_US en_US.UTF-8
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

echo America/New_York > /etc/timezone
timedatectl set-timezone America/New_York
```

Replace chinese software repositories with Debian software repositories.

```bash
cat > /etc/apt/sources.list <<'EOF'
deb http://deb.debian.org/debian bookworm contrib main non-free-firmware
deb http://deb.debian.org/debian bookworm-updates contrib main non-free-firmware
deb http://deb.debian.org/debian bookworm-backports contrib main non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security contrib main non-free-firmware
EOF
```

Remove unnecessary or untrusted packages.

```bash
apt remove containerd.io docker-ce docker-ce-cli libpkcs11-helper1 openvpn orangepi-zsh tmux zsh zsh-common
rm /etc/apt/sources.list.d/docker.list
rm /etc/docker/daemon.json
apt autoremove
apt clean
```

Disable unnecessary services.

```bash
systemctl set-default multi-user.target
systemctl disable orangepi-firstrun-config.service
systemctl disable orangepi-zram-config
systemctl disable orangepi-ramlog
```

Install fail2ban which will automatically block via firewall failed SSH login
attempts.

    apt update
    apt install fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban

Upgrade system packages

    apt update
    apt upgrade
    reboot

Restrict 2GB `/tmp` space and provide 8GB swap space (virtual RAM).

```bash
dd if=/dev/zero of=/tmp2g bs=128M count=16 oflag=dsync status=progress
dd if=/dev/zero of=/swapfile bs=128M count=64 oflag=dsync status=progress
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

reboot
```

Enabling the firewall will come later after home assistant is installed.

# Install Home Assistant

### Home Assistant Prerequisites

Verify `/etc/os-release` has

    PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"

Install [Docker for Debian][docker].

```bash
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt update
apt install docker-ce
systemctl enable docker
```

Configure logrotate for Docker.

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

And restart docker.

    systemctl restart docker

Following [Home Assistant Supervised][ha-super], install prerequisite packages.

```bash
apt install -y apparmor bluez cifs-utils curl dbus jq libglib2.0-bin \
    lsb-release network-manager nfs-common systemd-journal-remote \
    systemd-resolved udisks2 wget

reboot
```

### Install Home Assistant OS Agent and Supervised

Download and install [latest Home Assistant OS Agent][os-agent-latest].

    curl -sSfLO https://github.com/home-assistant/os-agent/releases/download/1.6.0/os-agent_1.6.0_linux_aarch64.deb
    dpkg -i os-agent_1.6.0_linux_aarch64.deb
    gdbus introspect --system --dest io.hass.os --object-path /io/hass/os

Download and install [latest Home Assistant Supervised][latest].

    curl -sSfLO https://github.com/home-assistant/supervised-installer/releases/download/2.0.0/homeassistant-supervised.deb
    dpkg -i homeassistant-supervised.deb

In the menu choose qemu-arm64 (nothing else really fits well with the allwinner CPU).

### Enable cgroup v1

Enable cgroup v1 by modifying `/boot/orangepiEnv.txt` appending to the bottom
the following.

```
extraargs=apparmor=1 security=apparmor systemd.unified_cgroup_hierarchy=false systemd.legacy_systemd_cgroup_controller=false
```

# Enabling web interface with secured TLS

Edit `/usr/share/hassio/homeassistant/configuration.yaml` and add

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.0.0.0/8
    - 127.0.0.1
```

Create TLS certificates

```bash
git clone https://github.com/samrocketman/my_internal_ca.git
cd my_internal_ca
# created a .env file based on README.md
./setup_ca.sh

# create TLS certificate for Home Assistant
./lan_server.sh homeassistant
```

Install nginx

    apt install nginx

Copy certificates

```bash
mkdir /etc/nginx/certs
chmod 700 /etc/nginx/certs
cp -a /root/my_internal_ca/myCA/certs/homeassistant.crt /etc/nginx/certs/
cp -a /root/my_internal_ca/myCA/private/homeassistant.key /etc/nginx/certs/
```

Create Home Assistant TLS proxy.  Copy the following contents to
`/etc/nginx/conf.d/homeassistant.conf`.

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

Reload nginx

    systemctl reload nginx

Provide a frontend for clients to interact with nginx.  This means clients
should be able to visit an HTTP site to obtain the custom TLS certificate
authority for security interacting with Home Assistant.

Create a file `/var/www/html/index.html` with the following contents.

```html
<!DOCTYPE html>
<html>
<head>
<title>Server certificate authority</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>

<h1>iOS and other CA cert</h1>
<p><a href=myca.crt>myca.crt</a></p>

<h1>Android DER</h1>
<p><a href=myca.der>myca.der</a></p>

</body>
</html>
```

Copy the certificate authority and generate android-compatible certificate.

    cd /var/www/html/
    rm index.nginx-debian.html
    cp /root/my_internal_ca/myCA/certs/myca.crt ./
    openssl x509 -in myca.crt -outform DER -out myca.der

Reboot, visit the HTTP site and set up your browser with a certificate
authority.  Visit the HTTPS site.

# Enabling VPN and encrypted drive support

Enable Kernel modules (drivers).

    modprobe wireguard
    echo wireguard >> /etc/modules
    modprobe dm-crypt
    echo dm-crypt >> /etc/modules

Set up VPN and generate clients.

    git clone https://github.com/samrocketman/docker-wireguard.git
    cd docker-wireguard/
    # write a .env file with public IP
    ./scripts/pihole.sh start
    ./wvpn.sh start

Issuing new clients.

    ./wvpn.sh new_client "Sam's iPhone"
    ./wvpn.sh qrcode 10.90.80.1

Do the above procedure for each new client IP.

# Add iptables firewalls

Generate firewalls.

    iptables-save > iptables.rules
    ip6tables-save > iptables.rules

Edit `ip6tables.rules` and change `filter`

* From - `:INPUT ACCEPT [0:0]` To - `:INPUT DROP [0:0]`
* From - `:OUTPUT ACCEPT [0:0]` To - `:OUTPUT DROP [0:0]`

Edit `ip6tables.rules` and add the following rules to the `filter` chain.

```iptables
################################################################################
# Added by Sam
################################################################################
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -p udp -m state --state NEW -m udp --dport 53 -j ACCEPT
-A OUTPUT -p tcp -m state --state NEW -m tcp --dport 123 -j ACCEPT
-A OUTPUT -p udp -m state --state NEW -m udp --dport 123 -j ACCEPT
-A OUTPUT -p tcp -m state --state NEW -m multiport --dport 80,443 -j ACCEPT
################################################################################
# END Added by Sam
################################################################################
```

Edit `iptables.rules` and add the following rules to the `filter` chain.

```iptables
################################################################################
# Added by Sam
################################################################################
:INTERNAL - [0:0]
:INTERNAL_allow - [0:0]
:OUTPUT_allow - [0:0]
:WORLD_allow - [0:0]

# INPUT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -s 192.168.1.1 -j DROP
-A INPUT -i lo -j ACCEPT
-A INPUT -j INTERNAL
-A INPUT -s 172.0.0.0/8 -j ACCEPT
-A INPUT -j WORLD_allow
-A INPUT -j REJECT --reject-with icmp-host-prohibited

# world-wide allow VPN port
-A WORLD_allow -p udp -m state --state NEW -m udp --dport 443 -j ACCEPT

# INTERNAL
-A INTERNAL -s 192.168.1.0/24 -g INTERNAL_allow
-A INTERNAL_allow -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INTERNAL_allow -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
-A INTERNAL_allow -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
-A INTERNAL_allow -j RETURN

# OUTPUT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
-A OUTPUT -d 172.0.0.0/8 -j ACCEPT
-A OUTPUT -j OUTPUT_allow
-A OUTPUT -j REJECT --reject-with icmp-host-prohibited
-A OUTPUT_allow -d 192.168.1.0/24 -j ACCEPT
#Allow broadcast
-A OUTPUT_allow -d 255.255.255.255 -j ACCEPT
#Allow DNS
-A OUTPUT_allow -p udp -m state --state NEW -m udp --dport 53 -j ACCEPT
#Allow NTP
-A OUTPUT_allow -p tcp -m state --state NEW -m tcp --dport 123 -j ACCEPT
-A OUTPUT_allow -p udp -m state --state NEW -m udp --dport 123 -j ACCEPT
#system updates and web traffic
-A OUTPUT_allow -p tcp -m state --state NEW -m multiport --dport 80,443 -j ACCEPT
-A OUTPUT_allow -j RETURN

################################################################################
# END Added by Sam
################################################################################
```

Edit crontab with `crontab -e` and add the following cron sequences.

```cron
@reboot /bin/bash -c '/usr/sbin/iptables-restore < /root/iptables.rules'
@reboot /bin/bash -c '/usr/sbin/ip6tables-restore < /root/ip6tables.rules'
```

### Stop firewall

    iptables -F
    ip6tables -F

### Start firewall

You can reboot or run the following.

    iptables-restore < /root/iptables.rules
    ip6tables-restore < /root/ip6tables.rules

# Turn off LEDs on boot

Cron can be used to turn off the LEDs on boot.  I like doing it this way because
later I can script turning on the LEDs for visual notifications.

```bash
cat > /etc/cron.d/turn-off-leds <<'EOF'
@reboot root find /sys -type f -name trigger -path '*/leds/*' -exec /bin/sh -c 'echo none > "{}"' \;
EOF
```

[docker]: https://docs.docker.com/engine/install/debian/
[ha-super]: https://github.com/home-assistant/supervised-installer
[hardware]: http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-Zero-3.html
[latest]: https://github.com/home-assistant/supervised-installer/releases/latest
[os-agent-latest]: https://github.com/home-assistant/os-agent/releases/latest
[software]: http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-Zero-3.html
