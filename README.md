![jellyman](.github/banner-shadow.png?raw=true "Jellyfin Logo")
======

> v1.4.6 a Jellyfin Manager for the Jellyfin generic linux amd64.tar.gz package

> Tested on Fedora 34/35/36, Ubuntu 22.04, Manjaro 21.3.6

> Should work on Any Debian, Arch, or RHEL Based Distribution

### Features

* **Setup** - Sets up the initial install.
* **Update** - [URL - optional] Downloads and updates the current stable or supplied Jellyfin version.
* **Update-cli** - Updates this Jellyman CLI Tool.
* **Update Beta** Downloads and updates to the current Jellyfin Beta version.
* **Disable** - Disable the jellyfin.service.
* **Enable** - Enable the jellyfin.service
* **Start** - Start the jellyfin.service.
* **Stop** - Stop the jellyfin.service.
* **Restart** - Restart the jellyfin.service.
* **Status** - Get status information on jellyfin.service.
* **Backup** - Input a directroy to output the backup archive.
* **Import** - Import a .tar file to pick up where you left off on another system.
* **Get Version** - Get the current installed version of Jellyfin.
* **Remove Version** - Remove a specific version of Jellyfin
* **Version Switch** - Switch Jellyfin version for another previously installed version.
* **Recertify https** - Removes old https certifications and creates new ones for the next 365 days. 
* **Rename TV** - Batch renaming script for TV shows.
* **Library Scan** - Tell Jellyfin to scan your media library.
* **Change Port** - Change Jellyfins network port - Default = 8096.
* **Import API Key** - Import a new API key.
* **Uninstall** - Uninstalls Jellyfin and Jellyman completely (Ignores the Media Directory).

### Getting Started

```shell
git clone https://github.com/Smiley-McSmiles/jellyman
cd jellyman
chmod ug+x setup.sh
sudo ./setup.sh
```

## Usage

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
-p     Reset the permissions of Jellyfins Media Library.
-r     Restart Jellyfin.
-s     Start Jellyfin.
-S     Stop Jellyfin.
-t     Status of Jellyfin.
-u     [URL - optional] Downloads and updates the current stable or supplied Jellyfin version.
-U     Update Jellyman - The Jellyfin Manager
-ub    Update Jellyfin to the most recent Beta.
-v     Get the current version of Jellyfin.
-vs    Switch Jellyfin version for another previously installed version.
-rv    Remove a Jellyfin version.
-rc    Removes old https certifications and creates new ones for the next 365 days.
-rn    Batch renaming script for TV shows.
-ls    Tell Jellyfin to scan your media library.
-cp    Change Jellyfins http network port - Default = 8096.
-cps   Change Jellyfins https network port - Default = 8920.
-ik    Import an API key.
-X     Uninstall Jellyfin and Jellyman Completely.

EXAMPLE:
-To stop jellyfin, disable on startup, backup, and then start the jellyfin server:
'sudo jellyman -S -d -b /home/$USER/ -s'
```

### License

   This project is licensed under the [GPL V3.0 License](https://github.com/Smiley-McSmiles/jellyman/blob/main/LICENSE).

