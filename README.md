![jellyman](.github/banner-shadow.png?raw=true "Jellyman Logo")
======

> v1.5.7 - A Jellyfin Manager for the Jellyfin generic linux amd64, arm64, and armhf tar.gz packages

> Tested on Fedora 34/35/36, Ubuntu 22.04, Manjaro 21.3.6, EndeavourOS Artemis Neo, Linux Mint 21, and Rocky Linux 9.0

> Should work on Any Debian, Arch, or RHEL Based Distribution

### Description

Jellyman is a simple BASH program and CLI (Command Line Interface) tool for installing and managing Jellyfin. Most notably, The ability to download and install the Jellyfin Media Server and switch between already downloaded versions of Jellyfin on the fly. As well as create a full backup so you can move or import all your metadata and user information to another machine.

### Features

* **Setup** - Sets up the initial install.
* **Import Metadata and Configuration** - During setup, import your currently install Jellyfin configs and metadata.
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

### Example Install
```
|-------------------------------------------------------------------|
|                     No commands recognized                        |
|                      setup.sh options are:                        |
|                                                                   |
|  -i [jellyfin-backup.tar] Import .tar to pick up where you left   |
|                    off on another machine                         |
|                                                                   |
|                    -U Update Jellyman only.                       |
|-------------------------------------------------------------------|

Press ENTER to continue with first time setup or CTRL+C to exit...
[Pressed ENTER]

Fetching newest stable Jellyfin version...
Is there a current install of Jellyfin on this system? [y/N] : N

Please enter the default user for Jellyfin: jellyfin

Preparing to install needed dependancies for Jellyfin...
ID=fedora
Complete!
Last metadata expiration check: 1:03:15 ago on Wed 24 Aug 2022 01:50:56 PM CDT.
Package ffmpeg-5.0.1-3.fc36.x86_64 is already installed.
Package ffmpeg-devel-5.0.1-3.fc36.x86_64 is already installed.
Package ffmpeg-libs-5.0.1-3.fc36.x86_64 is already installed.
Package git-2.37.2-1.fc36.x86_64 is already installed.
Package openssl-1:3.0.5-1.fc36.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Setting Permissions for Jellyfin...
Unblocking port 8096 and 8920...

|-------------------------------------------------------------------|
|               Navigate to http://localhost:8096/                  |
|        in your Web Browser to claim your Jellyfin server          |
|-------------------------------------------------------------------|

|-------------------------------------------------------------------|
|         To enable https please enter 'sudo jellyman -rc'          |
|       (After you have navigated to the Jellyfin Dashboard)        |
|                                                                   |
|             To manage Jellyfin use 'jellyman -h'                  |
|-------------------------------------------------------------------|


|-----------------------------------------------|
|          No default directory found...        |
|     Please enter the root directory for       |
|              your Media Library               |
|    DO NOT ENTER YOUR USER DIRECTORY AS IT     |
|    WILL RESET PERMISSIONS OF THE ENTERED      |
|       DIRECTORY TO YOUR JELLYFIN USER         |
|-----------------------------------------------|
/testMediaDirectory

● jellyfin.service - Jellyfin Media Server - Installed by Jellyman
     Loaded: loaded (/usr/lib/systemd/system/jellyfin.service; enabled; vendor preset: disabled)
     Active: active (running) since Tue 2022-08-23 21:18:41 CDT; 17h ago
   Main PID: 944 (jellyfin.sh)
      Tasks: 18 (limit: 8736)
     Memory: 254.3M
        CPU: 22.173s
     CGroup: /system.slice/jellyfin.service
             ├─ 944 /bin/bash /opt/jellyfin/jellyfin.sh
             └─ 947 /opt/jellyfin/jellyfin/jellyfin -d /opt/jellyfin/data -C /opt/jellyfin/cache -c /opt/jellyfin/config -l /opt/jellyfin/log --ffmpeg /usr/share/ffmpeg/ffmpeg

Would you like to remove the git cloned directory $DIRECTORY? [Y/n] : Y
Removing git cloned directory:/home/smiley/jellyman
```

### Usage

```
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

### In case Jellyman wont upgrade itself

```shell
git clone https://github.com/Smiley-McSmiles/jellyman
cd jellyman
chmod ug+x setup.sh
sudo ./setup.sh -U
```

### License

   This project is licensed under the [GPL V3.0 License](https://github.com/Smiley-McSmiles/jellyman/blob/main/LICENSE).

