![jellyman](.github/banner-shadow.png?raw=true "Jellyman Logo")
=======

> v1.9.6 - A Jellyfin Manager for the Jellyfin generic linux amd64, arm64, and armhf tar.gz packages

> Tested on Fedora 34-40, Ubuntu 22.04-24.04, Manjaro 21.3.6, EndeavourOS Artemis Neo/Nova/Cassini Nova, Linux Mint 21, and Rocky/Alma/RHEL Linux 8.6/9.0

> Should work on Any Debian, Arch, or RHEL Based Distribution **with SystemD**

# Description

Jellyman is a lightweight BASH CLI (Command Line Interface) tool for installing and managing Jellyfin. Most notably, The ability to download and install the Jellyfin Media Server and switch between already downloaded versions of Jellyfin on the fly. As well as create a full backup (automatically or manually) so you can move or import all your metadata and user information to another machine.

# Getting Started

```sh
git clone https://github.com/Smiley-McSmiles/jellyman
cd jellyman
chmod ug+x setup.sh
sudo ./setup.sh
cd ~/
```

# Features

* **Setup** - Sets up the initial install.
* **Update** - [URL - optional] Downloads and updates the current stable or supplied Jellyfin version.
```
    └── NOTE - Supplied URL has to be formatted like: jellyfin_x.x.x-<ARCHITECTURE>.tar.gz
```
* **Update-Jellyman** - Updates this Jellyman CLI Tool.
```
    └── Checks and downloads most recent version from GitHub.
```
* **Update Beta** Downloads and updates to the current Jellyfin Beta version.
* **Disable** - Disable the jellyfin.service.
* **Enable** - Enable the jellyfin.service
* **Start** - Start the jellyfin.service.
* **Stop** - Stop the jellyfin.service.
* **Restart** - Restart the jellyfin.service.
* **Status** - Get status information on jellyfin.service.
* **Backup** - Input a directroy to output the backup archive.
```
    ├── jellyman -b "/path/to/backup/directory" will output a jellyfin-backup.tar to that directory.
    ├── jellyman -ba will perform an automatic backup. But only if automatic backups are set up.
    └── jellyman -bu will launch the automatic backup setup utility.
```
* **Import** - Import a .tar file to pick up where you left off on another system.
```
    ├── Media metadata will only import if your new OS/setup and old OS/setup media folders are exactly the same.
    └── User and Web-UI configurations will still import just fine however.
```
* **Fix Permissions** - [DIRECTORY - optional] Reset the permissions of Jellyfin's Media Library or supplied directory.
```
    └── Uses 'chmod -R 770' on your media directory.
```
* **Get Version** - Get the current installed version of Jellyfin and Jellyman.
* **Remove Version** - Remove a specific version of Jellyfin
```
    └── Provides a list of currently installed versions of Jellyfin for you to remove.
```
* **Version Download** - Download an available Jellyfin version from the stable repository.
```
    └── Provides a list of Jellyfin versions for you to download.
```
* **Version Switch** - Switch Jellyfin version for another previously installed version.
```
    └── Provides a list of currently installed versions of Jellyfin for you to switch to.
```
* **View Logs** - Select from a list of logs to view.
* **Search Media** - Search Media in your media directory/directories.
* **List Media** - Provide a tree list of all media (output saved to /tmp/media.txt).
* **Recertify https** - Removes old https certifications and creates new **self signed** keys for the next 365 days. 
* **Rename TV** - Batch renaming script for TV shows.
* **Library Scan** - Tell Jellyfin to scan your media library.
* **Change Port** - Change Jellyfins network ports.
* **Change Media Directory** - Changes the Media Directory/Directories for Jellyman.
* **Import API Key** - Import a new API key.
* **Transcode** - Transcode a file/directory with a GB per hour filter.
```
    ├── 1.5GB/hr is recommended for 1080p.
    ├── 3GB/hr is recommended for 4k.
    ├── Now uses AV1 codec (No HDR).
    └── Please be careful as this can delete media files.
         └──Select [no] to delete original files to preserve your media.
```
* **Uninstall** - Uninstalls Jellyfin and Jellyman completely 
```
    └── Does not remove backup archives or media files.
```

# Example Install

## Click to watch video example install
[![Tutorial](https://img.youtube.com/vi/sXvEWvffcFc/0.jpg)](https://www.youtube.com/watch?v=sXvEWvffcFc)

```sh
1. Start first time setup
2. Force update Jellyman
3. Import a jellyfin-backup.tar file

> Please select the number corresponding with the option you want to select.
[1-3] >>> 1

> Fetching newest stable Jellyfin version...
> WARNING: THIS OPTION IS HIGHLY UNSTABLE, ONLY USE IF YOU KNOW WHAT YOU ARE DOING!!!

> Is Jellyfin CURRENTLY installed on this system?
[y/N] >>> no

> Please enter the LINUX user for Jellyfin
[jellyfin] >>> jellyfin
> Linux user = jellyfin
> Unpacking /home/smiley/jellyman/jellyfin_10.9.8-amd64.tar.gz...
> Installing dependencies...
> Preparing to install needed dependancies for Jellyfin...
> ID=fedora
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 1:16:45 ago on Wed 31 Jul 2024 05:16:09 AM CDT.
> Setting Permissions for Jellyfin...
> Unblocking port 8096 and 8920...
success
success
success

> DONE

+-------------------------------------------------------------------+
|                 Navigate to http://localhost:8096/                |
|         in your Web Browser to claim your Jellyfin server         |
+-------------------------------------------------------------------+

+-------------------------------------------------------------------+
|         To enable https please enter 'sudo jellyman -rc'          |
|       (After you have navigated to the Jellyfin Dashboard)        |
|                                                                   |
|                To manage Jellyfin use 'jellyman -h'               |
+-------------------------------------------------------------------+

> Press 'q' to exit next screen
● jellyfin.service - Jellyfin Media Server - Installed by Jellyman
     Loaded: loaded (/usr/lib/systemd/system/jellyfin.service; enabled; preset: disabled)
    Drop-In: /usr/lib/systemd/system/service.d
             └─10-timeout-abort.conf
     Active: active (running) since Wed 2024-07-31 06:32:56 CDT; 5s ago
   Main PID: 11878 (jellyfin.sh)
      Tasks: 21 (limit: 23170)
     Memory: 112.8M (peak: 128.1M)
        CPU: 5.178s
     CGroup: /system.slice/jellyfin.service
             ├─11878 /bin/bash /opt/jellyfin/jellyfin.sh
             └─11879 /opt/jellyfin/jellyfin/jellyfin -d /opt/jellyfin/data -C /opt/jellyfin/cache -c /opt/jellyfin/config -l /opt/jellyfin/log --ffmpeg /usr/bin/ffmpeg

Jul 31 06:33:01 stronglap jellyfin.sh[11879]: [06:33:01] [INF] [6] MediaBrowser.MediaEncoding.Encoder.MediaEncoder: FFmpeg: /usr/bin/ffmpeg
Jul 31 06:33:01 stronglap jellyfin.sh[11879]: [06:33:01] [INF] [6] Emby.Server.Implementations.ApplicationHost: ServerId: 264746fa848346df86e221b850267006
Jul 31 06:33:01 stronglap jellyfin.sh[11879]: [06:33:01] [INF] [6] Emby.Server.Implementations.ApplicationHost: Core startup complete
Jul 31 06:33:01 stronglap jellyfin.sh[11879]: [06:33:01] [INF] [6] Main: Startup complete 0:00:04.8788077

> Would you like to remove the cloned git directory /home/smiley/jellyman?
[Y/n] >>> no
> Okay, keeping /home/smiley/jellyman
```

# Usage

```
Jellyman - The Jellyfin Manager
-Created by Smiley McSmiles

Syntax: jellyman -[COMMAND] [PARAMETER]

COMMANDS:
-b,   --backup               [DIRECTORY] Input directory to output backup archive.
-ba,  --backup-auto          Perform an automatic backup.
-bu,  --backup-utility       Start the automatic backup utility.
-d,   --disable              Disable Jellyfin on System Start.
-e,   --enable               Enable Jellyfin on System Start.
-h,   --help                 Print this Help.
-i,   --import               Display list of backup .tar files to Import and automatically restores the selected backup.
-p,   --permissions          [DIRECTORY - optional] Reset the permissions of Jellyfin's Media Library or supplied directory.
-r,   --restart              Restart Jellyfin.
-s,   --start                Start Jellyfin.
-S,   --stop                 Stop Jellyfin.
-t,   --status               Status of Jellyfin.
-sm,  --search-media         Search Media in your media directory/directories.
-lm,  --list-media           Provide a tree list of all media (output saved to /tmp/media.txt).
-u,   --update-jellyfin      [URL - optional] Downloads and updates the current stable or supplied Jellyfin version.
-U,   --update-jellyman      Update Jellyman - The Jellyfin Manager.
-ub,  --update-beta          Update Jellyfin to the most recent Beta.
-ls,  --library-scan         Tell Jellyfin to scan your media library.
-v,   --version              Get the current installed version of Jellyfin.
-vd,  --version-download     Download an available Jellyfin version from the stable repository.
-vs,  --version-switch       Switch Jellyfin version for another previously installed version.
-vr,  --version-remove       Remove a Jellyfin version.
-vl   --view-log             Choose from a list of logs to view.
-rc,  --recertify            Removes old https certifications and creates new ones for the next 365 days.
-rn,  --rename               Batch renaming script for TV shows.
-cp,  --change-http          Change Jellyfins http network port - Default = 8096.
-cps, --change-https         Change Jellyfins https network port - Default = 8920.
-ik,  --import-key           Import a Jellyfin API key (Needed for `-ls` command).
-md,  --media-directory      Change the Media Directory for Jellyman.
-tc,  --transcode            Transcode a file/directory with a GB per hour filter (1.5GB is recommended).
-tcp, --transcode-progress   View progress of the Transcode.
-tcs, --transcode-stop       Stop the current transcode process.
-X,   --uninstall            Uninstall Jellyfin and Jellyman Completely.

EXAMPLE:
- To stop jellyfin, disable on startup, and then get status of the jellyfin service:
├── "sudo jellyman --stop --disable --status"
└── "sudo jellyman -S -d -t"

```

### In case Jellyman wont upgrade itself

```shell
git clone https://github.com/Smiley-McSmiles/jellyman.git
cd jellyman
chmod ug+x setup.sh
sudo ./setup.sh -U
cd ~/
```

### License

   This project is licensed under the [GPL V3.0 License](https://github.com/Smiley-McSmiles/jellyman/blob/main/LICENSE).

