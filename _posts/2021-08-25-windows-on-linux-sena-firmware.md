---
layout: post
title: "Windows on Linux: SENA and USB Device Support"
category: engineering
tags:
 - programming
 - linux
 - windows
 - tips
year: 2021
month: 08
day: 25
published: true
type: markdown
---

* TOC
{:toc}

# Introduction and Audience

This article is loosely based on [a GitHub gist I wrote][gist] for updating my
SENA, but this includes more convenience automation via Vagrant; details to
follow.

This post describes how to provision Windows on Linux for free.  This process is
legal and does not involve illegally downloading software.  Microsoft provides
free Windows virtual machines through its _Microsoft Edge Developer_ program at
no cost to you, the user.

Minimum specifications to follow along with this article:

- 4 core CPU which has hardware virtualization extensions (check `/proc/cpuinfo`
  for `vme`, `vmx`, or both).  You may have to enable virtualization in your
  BIOS or UEFI which is not covered in this article.
- 16GB RAM.
- 30GB harddrive space free.  Windows 10 is pretty large and you'll require
  three times the size of Windows.  You'll need three times the size because
  you'll download a Windows virtual machine as a zip, extract the zip, and then
  install it within Vagrant.  You can clean up the download files when you're
  done which will free up 14GB of space.

### Audience

I'll assume you use Linux day to day and have some familiarization with computer
hardware.  While these instructions attempt to take into account beginners to
Linux it is not geared towards a beginner.  If you're new to Linux and this
article is confusing, then I recommend the following tutorials.  Once you've
gone through them you can come back to this page and try again.

Linux Journey web tutorials:

- Grasshopper: [Command Line][lj-cli]
- Grasshopper: [Advanced Text-Fu][lj-txt] although I personally like `vim`.  If
  you install `vim` on your machine, then you can run the `vimtutor` command to
  learn how to use it.
- Journeyman: [Devices][lj-dev]

### Why Windows on Linux?

It is a reality that I'll have some piece of hardware such as a Garmin
GPS or a SENA Motorcycle headset which needs firmware updates but only works
from Windows or Mac.  This guide is intended to provide instruction on how to
connect such hardware and update it from Linux using a Windows virtual machine
at no cost of ownership.

### About Software

This article will use a mix of free and proprietary software; all of which costs
no money to use.  The following is a summarized list.  Refer to the website of
each software for their given licensing and usage.

- [Microsoft Windows][windows].  No explanation required, I think.
- [Vagrant][vagrant] is software used to automate provisioning virtual machines.
  It provides convenience around installation and booting of virtual machines
  for VirtualBox.
- [VirtualBox][vbox] is a hypervisor and virtual machine technology.  It is
  widely availabot for Linux, Mac, and Windows.

### My machine

The following are the specifications for the machine I used for testing commands
and writing this blog post.

Software specifications:

```bash
$ uname -rms
Linux 5.4.0-81-generic x86_64

$ lsb_release -a
LSB Version:	core-9.20170808ubuntu1-noarch:printing-9.20170808ubuntu1-noarch:security-9.20170808ubuntu1-noarch
Distributor ID:	Ubuntu
Description:	Pop!_OS 18.04 LTS
Release:	18.04
Codename:	bionic

$ bash --version | head -n1
GNU bash, version 4.4.20(1)-release (x86_64-pc-linux-gnu)
```

Hardware specifications:

* Make/model: system76 Darter Pro model darp5
* Processor: Intel(R) Core(TM) i7-8565U CPU @ 1.80GHz 4 core/8 threads with
  vme/vmx extensions.  See `/proc/cpuinfo` to check if your processor has these
  virtualization extensions.
* Memory: 32GB RAM

# Install VirtualBox and Vagrant

You can find instructions for how to install VirtualBox and Vagrant from the
respective project website.

- [Instructions for VirtualBox][vbox-install].
- [Instructions for Vagrant][vagrant-install].

Install VirtualBox on Pop OS 18.04 and Ubuntu 18.04.

```bash
sudo apt-get install virtualbox virtualbox-dkms virtualbox-ext-pack virtualbox-guest-additions-iso virtualbox-qt
sudo usermod -a -G vboxusers "$USER"
```

> **Note:** Changes made by `usermod` command will not take effect until after
> you start a new login session.  I recommend restarting your computer for
> simplicity sake.  If you're on another Linux OS you can check the `/etc/group`
> file for the VirtualBox group you need to add to your user.

Installing Vagrant on Pop OS 18.04 and Ubuntu 18.04.

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
sudo apt-get install vagrant
```

You'll also want to install a plugin which automates installing VirtualBox guest
additions.

    vagrant plugin install vagrant-vbguest

### Download Windows

1. Visit [Microsoft Edge Developer Virtual Machines page][windows].
2. Under Virtual Machines choose MSEdge on Win10 x64.
3. Choose VM Platform: `Vagrant`.
4. Check your Downloads folder for `MSEdge.Win10.Vagrant.zip`.

### Add Windows to Vagrant

Go to your downloads directory and unzip the Zip file.

```bash
cd ~/Downloads/
unzip MSEdge.Win10.Vagrant.zip
```

Add the resulting `*.box` file to Vagrant with a name of your choice.  Since
Microsoft offers multiple versions of Windows I recommend naming the box similar
to the version of Windows you've downloaded.  This will give you additional
flexibility for importing additional versions of Windows.

    vagrant box add ./MSEdge\ -\ Win10.box --name windows/10edge

# Provisioning Windows

Windows will be automatically provisioned by using Vagrant.  Vagrant automates
booting and installing VirtualBox virtual machines.  Vagrant uses a file named
`Vagrantfile` to describe a virtual machine and its operating system.

### Vagrantfile

Create a `Windows` directory which will simplify managing your Vagrant virtual
machine.  All following commands will assume this working directory.

    mkdir ~/Windows
    cd ~/Windows/

Create a file named `~/Windows/Vagrantfile`.  Ensure it has the following
contents.

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "windows/10edge"
  config.vm.box_check_update = false
  # Windows remote management settings
  config.vm.guest = :windows
  config.vm.communicator = "winrm"
  config.winrm.username = "IEUser"
  config.winrm.password = "Passw0rd!"
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  config.vm.provider "virtualbox" do |vb|
    # Hardware settings
    vb.gui = true
    vb.cpus = "4"
    vb.memory = "8192"

    # Operating system
    vb.customize ["modifyvm", :id, "--ostype", 'Windows10_64']

    # Video Settings with remote desktop disabled
    vb.customize ["modifyvm", :id, "--vram", "256", "--accelerate3d", "on", "--vrde", "off"]

    # DVD Drive for VBox Guest Additions
    vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", "--port", "0", "--device", "1", "--type", "dvddrive", "--medium", "emptydrive"]

    # USB 3 support
    #USB 3 support may only be run once
    unless File.exists? "usb-setup-complete"
      vb.customize ["storagectl", :id, "--name", "USB", "--add", "usb", "--controller", "USB", "--hostiocache", "on"]
      vb.customize ["modifyvm", :id, "--usb", "on", "--usbxhci", "on"]
    end
  end

  # Switch logic for USB 3 support
  config.trigger.after :up do |trigger|
    trigger.info = "Checking usb-setup-complete..."
    trigger.run = {inline: "bash -c '[ -f usb-setup-complete ] || touch usb-setup-complete'"}
  end
  config.trigger.after :destroy do |trigger|
    trigger.info = "Removing usb-setup-complete..."
    trigger.run = {inline: "bash -c '[ ! -f usb-setup-complete ] || rm -f usb-setup-complete'"}
  end
end
```

> **Note:** USB 3 support is intentionally commented out.  This is because
> VirtualBox and Vagrant will fail with errors if you try to provision more than
> once adding a USB controller.  It will fail stating there's already a device
> named `USB`.  If you need USB support, then uncomment the code and provision
> the USB device initially.  Uncomment the code for subsequent startup.

A second note...

> **Note:** if you use another version of Windows be sure to change the
> operating system `--ostype`.  You can view a list of all supported OS types by
> running the following command in your terminal.
>
>     VBoxManage list ostypes

### First time Windows setup and Guest Additions

In order for Vagrant to properly manage the Windows VM you must do three steps.

1. Start Windows via Vagrant.
2. Log into Windows and enable Windows Remote Management.
3. Ensure VirtualBox Guest Additions is installed.  This is done automatically,
   but you want to make sure it was successful.

Provision and start Windows with the following command.

    vagrant up

As soon as the Windows login screen is visible log into the `IEUser` using the
password: `Passw0rd!`.  From the start menu search for `cmd`.  Right click on
_Command Prompt_ and select _Run as administrator_.  From the administrator
command prompt run the following command:

    WinRM quickconfig
    sc config WinRM start=auto

Choose `Y` to enable Windows Remote Management.  The second command will force
Windows Remote Management to always autostart without delay.  From this point,
Vagrant should automatically continue with setup and installation of VirtualBox
Guest additions.

This log shows the full output when you've completed all of the steps
successfully.

```
$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'windows/10edge'...
==> default: Matching MAC address for NAT networking...
==> default: Setting the name of the VM: Windows_default_1629924069660_49626
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 5985 (guest) => 55985 (host) (adapter 1)
    default: 5986 (guest) => 55986 (host) (adapter 1)
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: WinRM address: 127.0.0.1:55985
    default: WinRM username: IEUser
    default: WinRM execution_time_limit: PT2H
    default: WinRM transport: negotiate
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
    default: The guest additions on this VM do not match the installed version of
    default: VirtualBox! In most cases this is fine, but in rare cases it can
    default: prevent things such as shared folders from working properly. If you see
    default: shared folder errors, please make sure the guest additions within the
    default: virtual machine match the version of VirtualBox you have installed on
    default: your host and reload your VM.
    default: 
    default: Guest Additions Version: 6.0.4
    default: VirtualBox Version: 5.2
==> default: Mounting shared folders...
    default: /vagrant => /home/sam/Windows
```


You should see VirtualBox Guest Additions running from the Windows system tray
in the bottom right corner of the OS.

### Starting and stopping Windows

Always start Windows using Vagrant and shut down Windows from within the VM.  To
start Windows run the following command.  You must be in the same directory as
the `Vagrantfile` for all `vagrant` commands to succeed.

    cd ~/Windows/
    vagrant up

At the Windows login screen, enter the IEUser password: `Passw0rd!`.  This
password is also mentioned on the [Microsoft Edge Developer Virtual
Machines][windows] webpage.

To shut down Windows gracefully, run the following command.

    vagrant halt

> **Note:** you can also shut Windows down from its start menu.

If you would like to completely delete the Windows virtual machine, then you
must destroy it.  The following command will permanently delete Windows again
but it will still be available for provisioning through Vagrant.

    vagrant destroy

# Adding USB 3 support

Windows 10 was provisioned with USB 3 support enabled.  If you'd like to connect
your USB hardware to Windows, then you'll need to attach the device through
VirtualBox.

### Attaching USB Devices to VirtualBox

List all USB devices.

    lsusb

There are two pieces of information to take note when looking at the list of USB
devices.  The Vendor ID and Product ID.  You can use these to automatically
directly attach the USB device to Windows.

For example, let's take a look at my SENA hardware.  The following is `lsusb`
output.

    Bus 003 Device 005: ID 092b:5530 Sena Technologies, Inc.

You can get additional information about this USB device.

    lsusb -d 092b:5530 -v

1. Go to VirtualBox Manager (while the Windows computer is powered off). View
   the virtual machine settings.
2. Click on USB and off to the right there are tiny icons for adding and
   removing USB filters.
3. Add a new USB filter. In my case, I filled out the following settings.
   * Name: `Sena`
   * Vendor ID: `092b` (taken from `idVendor` in `lsusb` output)
   * Product ID: `5530` (taken from `idProduct` in `lsusb` output)

> **Note:** The rest of the USB filter settings I left alone. The fewer details
> you add to the filter the more broadly devices will match (e.g. you can just
> specify only the Vendor ID and Manufacturer to match all SENA devices).

Power off and disconnect the USB device.  Reconnect and power on the device.
Because of the USB filter, the device will automatically connect directly to the
virtual machine for Windows to manage next time it is powered on.

[gist]: https://gist.github.com/samrocketman/4749ef939f6e43e32923fe608de5bb07
[lj-cli]: https://linuxjourney.com/lesson/the-shell
[lj-dev]: https://linuxjourney.com/lesson/dev-directory
[lj-txt]: https://linuxjourney.com/lesson/regular-expressions-regex
[vagrant-install]: https://www.vagrantup.com/downloads
[vagrant]: https://www.vagrantup.com/
[vbox-install]: https://www.virtualbox.org/wiki/Downloads
[vbox]: https://www.virtualbox.org/
[windows]: https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/
