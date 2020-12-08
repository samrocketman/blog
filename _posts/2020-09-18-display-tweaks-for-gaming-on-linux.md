---
layout: post
title: Display tweaks for gaming on Linux
category: gaming
tags:
 - gaming
year: 2020
month: 09
day: 18
published: true
type: markdown
---

* TOC
{:toc}

# Covers

* Fix screen tearing.
* Fix game character continues moving after you stop pressing keys.
* Fix small WINE dialogs in 4K gaming.

# Fix screen tearing

Run `xrandr` on the terminal without arguments to see which of your displays is
connected.

Check the current status of `TearFree` for your connected display.

    xrandr --props | sed -n '/ connected /,/^[^ \t]/p'

Here's some example output.

```
DisplayPort-4 connected primary 3840x2160+0+0 (normal left inverted right x axis y axis) 527mm x 296mm
...
    TearFree: auto
        supported: off, on, auto
...
```

The display output on my system is `DisplayPort-4`.  The following will
temporarily set `TearFree` to be `on` so that it is definitely enabled.

    xrandr --output DisplayPort-4 --set TearFree on

You can check `xrandr --props` again to verify `TearFree` is enabled.

### Persist screen tearing fix

The above will apply `TearFree` on your X11 runtime, but it will reset on boot.
To persist it, you must apply the setting to X11 for your device at boot.  Get
your current display device (and the Kernel driver in-use) with the following
command.

```bash
# Show VGA class number (0300 on my system)
lspci -nn
# Print VGA controller and driver information
lspci -vmmk -d ::0300
```

On my system the result was the following

```
Slot:	03:00.0
Class:	VGA compatible controller
Vendor:	Advanced Micro Devices, Inc. [AMD/ATI]
Device:	Device 731f
SVendor:	ASRock Incorporation
SDevice:	Device 5103
Rev:	c1
Driver:	amdgpu
Module:	amdgpu
```

So the Vendor is `AMD` (partial match is okay) and the driver is `amdgpu`.  I
created the following X11 configuration.

```bash
sudo mkdir /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/amd.conf <<'EOF'
Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
    Option "TearFree" "true"
EndSection
EOF
```

After reboot, `xrandr` as used in the previous section should report `TearFree`
as being `on` (not `auto`).

# Unwanted character movement

If you're playing in WINE (and some native games) sometimes the character will
keep moving forward or whatever movement your were last holding your keys.  This
behavior is typical of key repeating.  Turn off X11 key repeating to see if the
behavior is fixed.

    xset r off

To turn it back on:

    xset r on

# Fix small WINE dialogs

I launched steam with lutris using the `Wine Steam` runner as [configured in
this post][rust-lutris].  I launched Steam which created an `explorer.exe`
process.  The wine dialogs were extremely small on my 4K display so I fixed them
using `winecfg`.

```
$ tr '\0' '\n' < /proc/"$(pgrep explorer.exe)"/environ | grep WINE
WINEPREFIX=/home/sam/.local/share/lutris/runners/winesteam/prefix64
WINE=/home/sam/.local/share/lutris/runners/wine/lutris-5.7-10-x86_64/bin/wine

$ export WINEPREFIX=~/.local/share/lutris/runners/winesteam/prefix64
$ export PATH=~/.local/share/lutris/runners/wine/lutris-5.7-10-x86_64/bin:"$PATH"
$ winecfg
```

In `winecfg` go to `Graphics` tab and double the `Screen resolution` to `192`
dpi to double the size of WINE dialogs. `96` dpi is the default.  `dpi` is dots
per inch.

# Verify your monitor refresh rate

Both my graphics card and monitor support 60Hz refresh rate.  However, out of
the box my monitor was configured to run at 30Hz refresh rate.

You can check with `xrandr` command.

```bash
# xrandr
DisplayPort-5 connected primary 3840x2160+0+0 (normal left inverted right x axis y axis) 527mm x 296mm
   3840x2160     29.98*+
   2560x1440     59.95
   2048x1280     59.99
   1920x1200     59.88
   1920x1080     60.00    60.00    50.00    59.94    24.00    23.98
   1600x1200     60.00
   1600x900      60.00
   1280x1024     75.02    60.02
   1152x864      75.00
   1280x720      60.00    50.00    59.94
   1024x768      75.03    60.00
   800x600       75.00    60.32
   720x576       50.00
   720x480       60.00    59.94
   640x480       75.00    60.00    59.94
   720x400       70.08
```

Notice `3840x2160 29.98*+` means I'm running in 4K resoltion at 30Hz.

In Dell Monitor settings,  I went through the menus:

- Under `Display`
- Select `Response Time`.
- And choose `Fast` (`Normal` and `Fast` are the only two settings in my
  monitor).

After adjusting those settings my monitor flickered and came back.  I ran xrandr
and verified my display was running at 60Hz.

```bash
# xrandr
DisplayPort-1 connected primary 3840x2160+0+0 (normal left inverted right x axis y axis) 527mm x 296mm
   3840x2160     60.00*+  29.98
   2560x1440     59.95
   2048x1280     59.99
   1920x1200     59.88
   1920x1080     60.00    60.00    50.00    59.94    24.00    23.98
   1600x1200     60.00
   1680x1050     60.00
   1600x900      60.00
   1280x1024     75.02    60.02
   1440x900      60.00
   1280x800      60.00
   1152x864      75.00
   1280x720      60.00    50.00    59.94
   1024x768      75.03    60.00
   800x600       75.00    60.32
   720x576       50.00
   720x480       60.00    59.94
   640x480       75.00    60.00    59.94
   720x400       70.08
```

Notice `3840x2160 60.00*+ 29.98`  means 30Hz and 60Hz are available and I am
running in 4K resolution at 60Hz (`*+` is the selected refresh rate).

[rust-lutris]: https://steamcommunity.com/sharedfiles/filedetails/?id=2219125189
