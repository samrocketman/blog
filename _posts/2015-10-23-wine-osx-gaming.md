---
layout: post
title: Windows-only games on Mac OS X
category: gaming
tags:
 - gaming
 - wine
 - osx
year: 2015
month: 10
day: 23
published: true
---

Recently I had a craving to play some Windows-only games on my Macbook Pro.  I
achieved this with [WINE][wine].  None of the online tutorials were sufficient
for Mac OS so I created this blog post.

The games I wanted to play were:

* [Fallout 3 Game of the year edition][wine-fallout]
* [S.T.A.L.K.E.R.: Call of Pripyat][wine-cop]

I contributed this install experience to the [WINE AppDB][wine-adb].

### Tech specs

Hardware:

* Macbook Pro Model A1398
* CPU: 2.3 GHz Intel Core i7
* RAM: 16 GB 1600 MHz DDR3
* GPU: NVIDIA GeForce GT 750M
* VRAM: 2048 MB

Software:

* OS X 10.9.5
* Xcode Version 6.0.1 (6A317) with developer tools installed
* [Homebrew 0.9.5][brew]
* I used homebrew to compile and install [WINE 1.7.53][wine-head]

Notes about software:

* Software progresses; at the time of this writing, the software used is the
  latest versions at the time.  I recommend you make use of the latest software
  and versions when you go through this tutorial rather than attempt to use the
  specific versions outlined in this guide.

# Install WINE on Mac OS X

After reading several tutorials, I instead opted to go a little more creative
route by using `homebrew`, `winetricks list-all`, and `winetricks dlls list`.
This allowed me to easily install all required prerequisites for the game with
little effort.

One of the great things about the `homebrew` version of `wine` is that I can
build the latest development branch from source.  The development branch is
usually pretty stable and you get the latest and greatest changes.  I discovered
that by doing `homebrew info wine`.

**Warning: when installing via winetricks careful not to touch your keyboard
until winetricks pauses with an installer dialog.  I've accidentally closed
installers.**

```bash
brew install wine --HEAD
brew install winetricks
winetricks corefonts
winetricks dlls msasn1
for x in d3dx9_43 d3dx10 d3dx11_43;do winetricks $x; done
for x in vcrun6sp6 vcrun2003 vcrun2005 vcrun2008 vcrun2010 vcrun2012 vcrun2013;do winetricks $x;done
for x in dotnet30sp1 quartz msxml3 dxdiag physx;do winetricks $x;done
```

That installed the base prerequisites for Fallout (as well as a few other extras
which are used by other games I play).  Now to configure wine.

```bash
winetricks winxp
winecfg
```

Once inside of `winecfg`, configure the _Graphics_ tab and enable "Automatically
capture the mouse in full-screen windows".

### Configure WINE with proper graphics

Once you have WINE setup, there's a few additional WINE registry entries which
need to be customized in order for the graphics to work well on Mac OS X.  In
order to properly force WINE to detect your graphics you must first look up your
own hardware settings using the Mac utility "System Information."

##### View Mac "System Information"

1. Click on the Apple icon in the upper left of your screen.
2. Select _About this Mac_.
3. Select _More Info..._ button.
4. View the section under _Hardware > Graphics/Displays_.
5. View information about the NVIDIA onboard graphics.  For the Macbook Pro
   Model A1398 the settings are the following.
   * Vendor: NVIDIA (0x10de)
   * Device ID: 0x0fe9
   * VRAM (Total): 2048 MB

The hex values for _Vendor_ and _Device ID_ are important in the following
section.

##### Update WINE registry with proper graphics

1. Open the wine registry with the command `wine regedit`.
2. Create the registry key and values:
  * Create key: `HKEY_CURRENT_USER\Software\Wine\Direct3D`.  Within this key
    create the following values.
    * Create DWORD Value `VideoPciDeviceID` and set the value to `0x00000fe9`.
    * Create DWORD Value `VideoPciVendorID` and set the value to `0x000010de`.
    * Create the String Value `VideoMemorySize` and set the value to `1024`.  This value is in megabytes.

Notes:

* This should resolve a crash resulting from "fatal error C9008: out of memory -
  malloc failed; Cg compiler terminated due to fatal error".
* Even though the graphics card has 2048MB of video memory.  Set the Direct3D
  video memory size far below to avoid over allocation.  Over allocation occurs
  with fatal out of memory errors.  Some games crash as a result of this issue.

# Install Steam and Games

Now we're ready to install Steam.  _Note: don't automatically launch Steam when
the install is finished._

```bash
winetricks steam
```

Start Steam and install Fallout 3 GOTY Edition and S.T.A.L.K.E.R.: Call of
Pripyat.  You can start Steam with the following command from the terminal.

```bash
wine 'C:\\Program Files\\Steam\\Steam.exe'
```

After Fallout is installed, don't forget to enable all of the optional DLC (from
the Fallout Launcher visit DATA FILES and enable them).  Occasionally, there are
a few graphics quirks but overall the game performs well.

### Recommended Steam settings

Since the Web renderer doesn't work in Steam there's no point in displaying the
Store page or product updates.  Here's a list of settings I customized.

* Settings > In-Game
  * Disable steam overlay while in-game
* Settings > Interface
  * Favorite window set to Library.
  * Disable Run steam when my computer starts (setting doesn't really matter
    since it's wine).
  * Disable Notify me about additions or changes to my games, new releases, and
    upcoming releases.

# Fallout 3 GOTY optimizations

Open Fallout once and then close it.  This will create the game configuration
files in `~/Documents/My Games/Fallout3`.

Apply the [`FALLOUT.INI` patch][fallout-ini.patch] with the following commands.

```bash
cd "~/Documents/My Games/Fallout3"
curl -L "http://bit.ly/1WaaDQf" | patch
```

###### Known issues

* Setting `bMultiThreadAudio=1` in `FALLOUT.INI` will cause the game to hang on
  exit.  If the audio becomes a performance issue then enable this setting.
  Otherwise, just leave it default (set to `bMultiThreadAudio=0`).
* You may encounter an issue where graphics bug out when viewing your pip boy
  and other menus.  It looks like assets fail to load.  This may occur even with
  the `FALLOUT.INI` patch installed. I found the following corrects this issue.
  1. In FalloutLauncher, click on _OPTIONS_.
  2. Click the _Advanced_ button.
  3. Click the _Water_ tab.
  4. Disable _Water Refractions_ and _Water Reflections_.  All other water
     settings can be left the same.

##### Other graphics settings

Set all graphics to Ultra and enabled max viewing distances.  This game can be
played with the graphics turned up to max for available settings.


##### Tested screen resolutions

Performant configurations (very performant):

* 1280x800 windowed, WINE VRAM set to 1024 MB
* 1280x800 full screen, WINE VRAM set to 1024 MB
* 1440x900 full screen, WINE VRAM set to 1024 MB

Tested but with multiple issues:

* 1280x800 windowed, WINE VRAM set to 2048 MB - very performant but occasionally
  crashes with out of memory errors.
* 1280x800 full screen, WINE VRAM set to 2048 MB - very performant but
  occasionally crashes with out of memory errors.
* 2880x800 full screen, WINE VRAM set to 2048 MB - Menus and load screens are
  smooth but when loading the game it is unplayable.

# S.T.A.L.K.E.R.: Call of Pripyat optimizations

No additional optimizations required.  No known issues encountered that aren't
issues on Windows.

##### Other graphics settings

Set all graphics to highest settings and enabled max viewing distances.  This
game can be played with the graphics turned up to max settings.

##### Tested screen resolutions

Performant configurations (very performant):

* 1280x800 windowed, WINE VRAM set to 1024 MB
* 1280x800 full screen, WINE VRAM set to 1024 MB
* 2880x800 full screen, WINE VRAM set to 2048 MB

Even at 2880x800 resolution with 2048 MB VRAM configured in WINE, the game
performed well and didn't crash with any out of memory issues.

# Conclusion

My experience using WINE on Mac OS X to play graphics intense games has been
great on a Macbook Pro.  Let me know in the comments, if you try out these
instructions, how it went.

[brew]: http://brew.sh/
[fallout-ini.patch]: https://gist.github.com/samrocketman/bd24e426e6fe625810ef
[wine-adb]: https://appdb.winehq.org/
[wine-cop]: https://appdb.winehq.org/objectManager.php?sClass=version&iId=18649
[wine-fallout]: https://appdb.winehq.org/objectManager.php?sClass=version&iId=14322
[wine-head]: https://source.winehq.org/git/wine.git/commit/65d699eb5f7fc151197f3dc9f36499ee3e43f8e7
[wine]: https://www.winehq.org/
