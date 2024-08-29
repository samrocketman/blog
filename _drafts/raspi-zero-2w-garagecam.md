# Firewalls

Install iptablesscripts.

```
apt install netscript-ipfilter
```

IPv4

```
# Generated by iptables-save v1.8.9 (nf_tables) on Wed Aug 28 19:49:11 2024
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:OUTPUT_allow - [0:0]
:INTERNAL - [0:0]
:INTERNAL_allow - [0:0]
:LOGGING - [0:0]

# input
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -j INTERNAL
-A INPUT -j LOGGING
-A INPUT -j REJECT --reject-with icmp-host-prohibited

# output
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -j OUTPUT_allow
-A OUTPUT -j REJECT --reject-with icmp-host-prohibited

# allowed outbound traffic
# only internal dns
-A OUTPUT_allow -p udp -d 192.168.1.254 -m state --state NEW -m udp --dport 53 -j ACCEPT
-A OUTPUT_allow -p tcp -d 192.168.1.254 -m state --state NEW -m tcp --dport 53 -j ACCEPT
# ntp
-A OUTPUT_allow -p tcp -m state --state NEW -m tcp --dport 123 -j ACCEPT
-A OUTPUT_allow -p udp -m state --state NEW -m udp --dport 123 -j ACCEPT
#-A OUTPUT_allow -p tcp -m state --state NEW -m multiport --dport 21,80,443 -j ACCEPT

# internal networks
-A INTERNAL -s 192.168.1.0/24 -g INTERNAL_allow

# internal services
-A INTERNAL_allow -p tcp -m tcp --dport 22 -j ACCEPT
#rtsp
-A INTERNAL_allow -p tcp -m tcp --dport 8554 -j ACCEPT
#-A INTERNAL_allow -p udp -m udp --dport 8554 -j ACCEPT
-A INTERNAL_allow -p udp -m udp --dport 8000 -j ACCEPT
-A INTERNAL_allow -p udp -m udp --dport 8001 -j ACCEPT
-A INTERNAL_allow -j RETURN

# logging rejections for troubleshooting
# change the following IP to the host you want to troubleshoot
#-A LOGGING ! -s 192.168.1.238 -j RETURN
#-A LOGGING -m limit --limit 1/second -j LOG --log-prefix "iptables DROP: " --log-level 4
# see dmesg logs for iptables DROP entries

COMMIT
# Completed on Wed Aug 28 19:49:11 2024
```

IPv6

```


Set up reboot crontab

```
@reboot /bin/bash -c '/usr/sbin/iptables-restore < /root/firewall'

@reboot /bin/bash -c '/usr/sbin/ip6tables-restore < /root/ipv6-firewall'
```

Update script which includes punching a hole in the firewall temporarily on
update.

```bash
#!/bin/bash
set -auxo pipefail

iptables -A OUTPUT_allow -p tcp -m state --state NEW -m multiport --dport 21,80,443 -j ACCEPT
apt update
apt upgrade
iptables -D OUTPUT_allow -p tcp -m state --state NEW -m multiport --dport 21,80,443 -j ACCEPT
```

# Enable Arducam camera hardware

I have an 8MP arducam.

https://docs.arducam.com/Raspberry-Pi-Camera/Native-camera/8MP-IMX219/

```bash
vim /boot/firmware/config.txt
#Find the line: camera_auto_detect=1, update it to:
camera_auto_detect=0
#Find the line: [all], add the following item under it:
dtoverlay=imx219
#Save and reboot.
```

# Set up RTSP server

```bash
mkdir /opt/mediamtx
cd /opt/mediamtx
url=https://github.com/bluenviron/mediamtx/releases/download/v1.9.0/mediamtx_v1.9.0_linux_arm64v8.tar.gz
curl -sSfLO "$url" | tar -xz
```

I changed the yaml config with the following settings so there's RTSP UDP only.

```diff
--- mediamtx.yml.original	2024-08-26 11:55:09.000000000 -0400
+++ mediamtx.yml	2024-08-28 20:19:16.486796342 -0400
@@ -227,7 +227,8 @@
 # UDP-multicast allows to save bandwidth when clients are all in the same LAN.
 # TCP is the most versatile, and does support encryption.
 # The handshake is always performed with TCP.
-protocols: [udp, multicast, tcp]
+#protocols: [udp, multicast, tcp]
+protocols: [udp]
 # Encrypt handshakes and TCP streams with TLS (RTSPS).
 # Available values are "no", "strict", "optional".
 encryption: "no"
@@ -260,7 +261,7 @@
 # Global settings -> RTMP server

 # Enable publishing and reading streams with the RTMP protocol.
-rtmp: yes
+rtmp: no
 # Address of the RTMP listener. This is needed only when encryption is "no" or "optional".
 rtmpAddress: :1935
 # Encrypt connections with TLS (RTMPS).
@@ -280,7 +281,7 @@
 # Global settings -> HLS server

 # Enable reading streams with the HLS protocol.
-hls: yes
+hls: no
 # Address of the HLS listener.
 hlsAddress: :8888
 # Enable TLS/HTTPS on the HLS server.
@@ -339,7 +340,7 @@
 # Global settings -> WebRTC server

 # Enable publishing and reading streams with the WebRTC protocol.
-webrtc: yes
+webrtc: no
 # Address of the WebRTC HTTP listener.
 webrtcAddress: :8889
 # Enable TLS/HTTPS on the WebRTC server.
@@ -392,7 +393,7 @@
 # Global settings -> SRT server

 # Enable publishing and reading streams with the SRT protocol.
-srt: yes
+srt: no
 # Address of the SRT listener.
 srtAddress: :8890

@@ -699,6 +700,10 @@
   # example:
   # my_camera:
   #   source: rtsp://my_camera
+  garage:
+    source: rpiCamera
+    rpiCameraWidth: 1280
+    rpiCameraHeight: 720

   # Settings under path "all_others" are applied to all paths that
   # do not match another entry.
```

Autostart on reboot.  Create systemd service

* At location: `/etc/systemd/system/rtsp-server.service`
* With the following contents.

```ini
[Unit]
Description=RTSP server for arducam
Wants=network.target
[Service]
Restart=on-failure
RestartSec=5s
ExecStart=/opt/mediamtx/mediamtx /opt/mediamtx/mediamtx.yml
[Install]
WantedBy=multi-user.target
```

Enable autostarting

```
systemctl daemon-reload
systemctl enable rtsp-server
systemctl start rtsp-server
```