![jellyman](.github/banner-shadow.png?raw=true "Jellyman Logo")
======

> v1.5.0 - a Jellyfin Manager for the Jellyfin generic linux amd64, arm64, and armhf tar.gz packages

> Tested on Fedora 34/35/36, Ubuntu 22.04, Manjaro 21.3.6, and Linux Mint 21

> Should work on Any Debian, Arch, or RHEL Based Distribution

### Description

Jellyman is a simple and an easy to understand CLI(Command Line Interface) tool for installing and managing Jellyfin. Most notably, the ability to switch between already downloaded versions of Jellyfin on the fly, and create a full backup so you can move or import all your metadata and user information to another machine. This program can start, stop, enable or disable on startup, check for updates for stable or beta releases, tell Jellyfin to do a library scan, reset media permissions, and many other things.


### Features

* **Setup** - Sets up the initial install.
* **Update** - [URL - optional] Downloads and updates the current stable or supplied Jellyfin version.
* **Update-Jellyman** - Updates this Jellyman CLI Tool.
* **Update Beta** Downloads and updates to the current Jellyfin Beta version.
* **Disable** - Disable the jellyfin.service.
* **Enable** - Enable the jellyfin.service
* **Start** - Start the jellyfin.service.
* **Stop** - Stop the jellyfin.service.
* **Restart** - Restart the jellyfin.service.
* **Status** - Get status information on jellyfin.service.
* **Backup** - Input a directroy to output the backup archive.
* **Import** - Import a .tar file to pick up where you left off on another system.
* **Fix Permissions** - [DIRECTORY - optional] Reset the permissions of Jellyfin's Media Library or supplied directory.
* **Get Version** - Get the current installed version of Jellyfin.
* **Remove Version** - Remove a specific version of Jellyfin
* **Version Download** - Download an available Jellyfin version from the stable repository.
* **Version Switch** - Switch Jellyfin version for another previously installed version.
* **Recertify https** - Removes old https certifications and creates new ones for the next 365 days. 
* **Rename TV** - Batch renaming script for TV shows.
* **Library Scan** - Tell Jellyfin to scan your media library.
* **Change Port** - Change Jellyfins network port - Default = 8096.
* **Change Media Directory** - Changes the Media Directory/Directories for Jellyman.
* **Import API Key** - Import a new API key.
* **Uninstall** - Uninstalls Jellyfin and Jellyman completely (Ignores the Media Directory).

### Getting Started

```shell
git clone https://github.com/Smiley-McSmiles/jellyman
cd jellyman
chmod ug+x setup.sh
sudo ./setup.sh
```

### Usage

```shell
Jellyman - The Jellyfin Manager
-Created by Smiley McSmiles

Syntax: jellyman -[COMMAND] [PARAMETER]

COMMANDS:
-b     [DIRECTORY] Input directory to output backup archive.
-d     Disable Jellyfin on System Start.
-e     Enable Jellyfin on System Start.
-h     Print this Help.
-i     [FILE.tar] Input file to Import jellyfin-backup.tar.
-p     [DIRECTORY - optional] Reset the permissions of Jellyfins Media Library or supplied directory.
-r     Restart Jellyfin.
-s     Start Jellyfin.
-S     Stop Jellyfin.
-t     Status of Jellyfin.
-u     [URL - optional] Downloads and updates the current stable or supplied Jellyfin version.
-U     Update Jellyman - The Jellyfin Manager
-ub    Update Jellyfin to the most recent Beta.
-v     Get the current version of Jellyfin.
-vd    Download an available Jellyfin version from the stable repository.
-vs    Switch Jellyfin version for another previously installed version.
-rv    Remove a Jellyfin version.
-rc    Removes old https certifications and creates new ones for the next 365 days.
-rn    Batch renaming script for TV shows.
-ls    Tell Jellyfin to scan your media library.
-cp    Change Jellyfins http network port - Default = 8096.
-cps   Change Jellyfins https network port - Default = 8920.
-ik    Import an API key.
-md    Change the Media Directory for Jellyman.
-X     Uninstall Jellyfin and Jellyman Completely.

EXAMPLE:
-To stop jellyfin, disable on startup, backup, and then start the jellyfin server:
'sudo jellyman -S -d -b /home/$USER/ -s'
```

### License

   This project is licensed under the [GPL V3.0 License](https://github.com/Smiley-McSmiles/jellyman/blob/main/LICENSE).

