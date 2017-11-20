---
layout: post
title: "Install and play ES3: Morrowind on Linux"
category: gaming
tags:
 - gaming
 - linux
year: 2017
month: 11
day: 04
published: true
type: markdown
---

The first open world exploration game I played was [Elder Scrolls III:
Morrowind][es-mw].  It is very different from what I would call "modern" open
world exploration games (even from the same Elder Scrolls series).  I actually
enjoyed the game play more.

# Why I enjoy Morrowind

Morrowind, for me, is enjoyable because:

- There is no fast travel; at least not like newer games.  One [can only fast
  travel from designated points][mw-ft] like Boats, Gondolas, Stilt Striders,
  and Propylon Chambers.
  - Why is this cool?  It emphasizes the importance of skills in the game: speed
    and acrobatics.  It really matters how quickly you can travel on your feet.
- There aren't really any map markers and the world map starts out with a [fog
  of war][mw-fog].  That is, the map isn't revealed and a player is forced to
  explore in order to reveal it.  There's also no quest markers so this adds to
  both the difficulty and a bit of investigative gameplay.
  - Why is this cool?  I have to investigate by asking non-player characters
    questions around the town.  They give you general directions like North,
    East, South, West, or in between.  Then you follow the roads in those
    general directions and look for road signs to the destination you're
    traveling.  This adds an element of uncertainty and allows a player to
    explore and investigate like a detective.
- At the beginning of the game your character actually sucks.  What I mean is,
  let's say you have all basic stats; if you try using a sword your character is
  going to be terrible at it.  You're lucky if you hit the enemy with 1 out of
  10 swings.  As you level up your sword skill, your character gets better at
  hitting enemies until eventually it always hits enemies.
  - Why is this cool?  Again, it forces me to think about what stats I value
    early on in the game.  Depending on the style I want to play I have to
    invest in certain stats over others.

These are just a few reasons I love Morrowind over other games of its kind.

# Installing Morrowind in Linux

[OpenMW][omw] (a.k.a. Open Morrowind) is a project that aims to make Morrowind
multi-platform.  So far, I've put a few hours into it and haven't encountered
any noticeable bugs.  I think it's a great port and it loads Morrowind extremely
fast on my laptop.  OpenMW allows Morrowind to be available for many platforms
such as Mac OS X, Linux, and even Windows (though Morrowind was initially
available for Windows).

[Download and install OpenMW][omw-dl].

Purchase and download the [GOG.com version of Morrowind][gog].  On my computer,
it downloaded to `~/Downloads/setup_tes_morrowind_goty_2.0.0.7.exe`.  Use
`innoextract` to access the game files from the installer.

```bash
sudo apt-get install innoextract
mkdir -p ~/usr/games/morrowind
cd ~/usr/games/morrowind
innoextract ~/Downloads/setup_tes_morrowind_goty_2.0.0.7.exe
```

Open the _OpenMW Launcher_, it will prompt you to go through a wizard to search
for the game files.  The game files are located in
`~/usr/games/morrowind/app/Data Files`.  After the game files are set up and the
OpenMW Launcher is open, visit the _Data Files_ tab of the launcher.  Enable all
of the available expansions and DLC available in the list.  Configure the
graphics to your liking and then launch.

Enjoy the game.

[es-mw]: https://en.wikipedia.org/wiki/The_Elder_Scrolls_III:_Morrowind
[gog]: https://www.gog.com/game/the_elder_scrolls_iii_morrowind_goty_edition
[mw-fog]: https://en.wikipedia.org/wiki/Fog_of_war#In_video_games
[mw-ft]: https://www.gamefaqs.com/xbox/480241-the-elder-scrolls-iii-morrowind/answers/231311-fast-travelling
[omw-dl]: https://openmw.org/downloads/
[omw]: https://openmw.org/
