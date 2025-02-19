# CHANGELOG.md for https://GitHub.com/Smiley-McSmiles/jellyman

# Jellyman v1.9.6
## Fixes
- Fixed bug where automatic backup was deleting newer backup files since December->January

# Jellyman v1.9.5
## Fixes
- Fixed `setup.sh` failing to install jellyfin on RHEL 9 based systems. (Thank you cstackpole)

# Jellyman v1.9.4
## Changes
- jellyman.log now keeps 5000 lines instead of 1000.
- Updated the `--help` command.
- Changed some laguage outputs.
- Added help info for `less` command (`jellyman -vl`)

## Additions 
- `-sm,  --search-media         Search Media in your media directory/directories.`
- `-lm,  --list-media           Provide a tree list of all media (output saved to /tmp/media.txt).`

## Fixes
- Fixed the `HasSudo` checker

# Jellyman v1.9.3
## Fixes
- Fixed issue with jellyfin.service during setup.

# Jellyman v1.9.2
## Changes
- setup.sh no longer has an option to migrate data from one install to another install.
  - This option has caused a lot of headache to get to work correctly. If you are a BASH programmer, please feel free to post a pull request to add this _feature_ back in (If you can get migrating to work reliably across many different types of jellyfin installs)

# Jellyman v1.9.1
## Additions
- Added fail safe for deleting files during transcode, to make sure to not delete files if the transcode failed for any reason.

## Fixes
- `jellyman -tc` would keep multiplying the desired GB/hour when trying to qualify multiple files.
- `jellyman -tc` would fail if encoding a non HDR video using hardware acceleration.

# Jellyman v1.9.0
## Additions
- Added hardware acceleration to `jellyman -tc`

# Jellyman v1.8.9
## Fixes
- `jellyman -tc` was not copying over all audio streams.

# Jellyman v1.8.8
## Additions
- `jellyman -tcp` now gives projected size and percentage of space saved per file.

## Changes
- Many language and readability changes to `jellyman -tc` and `-tcp`
- Logging more verbose with transcodes.

# Jellyman v1.8.7
## Changes
- Many language and readability changes to `jellyman -tc` and `-tcp`

## Additions
- User can now choose which encoder they want to use in the guided `jellyman -tc` encoder
- Support for GPU encoding with `jellyman -tc`
- Encoding now fully preserves subtitle streams.
- Encoder moved to the `.mkv` container

# Jellyman v1.8.6
## Fixes
- Fix for `jellyman -tc` not recognizing HDR in file names with spaces.

# Jellyman v1.8.5
## Fixes
- Fix for `jellyman -tcp` with files including multiple periods '.'

# Jellyman v1.8.4
## Fixes
- Fix for `jellyman -tcp` with files including '( )'
- Fix for `jellyman -tc` with some files having multiple 'steams' and getting wrong width and duration information.

# Jellyman v1.8.3
## Additions
- Jellyman setup and update now installs the latest jellyfin-ffmpeg archive by default.

# Jellyman v1.8.2
## Fixes
- `jellyman -rn` was broken due to the wrong PromptUser type

## Changes
- `jellyman -tc` Will now recognize HDR and 4K content, and transcode the new files using HDR. The qualifier will now multiply the GB/hr for 1080p content by 2.5 to qualify 4K content.

## Additions
- `CHANGELOG.md` has been added.

# Jellyman v1.8.1
## Changes
- Changed base_functions.sh to jellyman-functions for conflict reasons
- Changed how the ViewLog works in the code.
- Added a function in jellyman-functions for PresentList (Handles presenting lists and logs the selected item in the list
- Changed some error language.

# Jellyman v1.8.0
## Additions
- `jellyman -vl` Choose from a list of logs to view.
- Jellyman now logs things during setup.sh and when using Jellyman. See /opt/jellyfin/log for details. Or use the new `jellyman -vl` to view those logs.
- Added option in `jellyman -bu` to initiate a backup.

## Fixes
- Typos in `jellyan -i` and `setup.sh` import
- Fixed Jellyfin Linux user mismatch on import not changing User variable in the jellyfin.service file
- `jellyman -vr` would allow the user to remove the current version of Jellyfin.
- `jellyman -vd` would allow the user to download the current version of Jellyfin.

## Changes
 - All functions are now Pascal Case

# Jellyman v1.7.9
## Fixes
 - Bug in base_functions.sh preventing strings from passing in variables
 - Bug in `jellyman -tc` not passing variable properly to the transcode qualifier
 - Bug in `jellyman -md` not passing variable properly to change media directory

#  Jellyman v1.7.8
## Fixes
 - Prevents user from running `sudo ./setup.sh -U` without first having Jellyman installed.
 - Updated README.md to have a more current Example Install section
 - Fixed bug where systemD services would fail being moved during import using a different distribution
 - Fixed `jellyman -vr` not working due to it still being `jellyman -rv`...
 - HOTFIX `jellyman -vr` variable broken, resulting in deletion of /opt/jellyfin

## Changes
 - Removed verbosity of extract tar command in setup.sh
 - `jellyman -tc` now uses AV1 format

# Jellyman v1.7.7
## Additions
 - Added function `Del_var` which deletes a variable in a file.
 - Added more verbose prompt examles
 
## Fixed 
 - `jellyman -ls` command using old `$netowrkPort` variable, thus not actually calling Jellyfin to initiate library scan
 - Fixed mkdir errors
 - Fix for jellyfin.service not being placed in the right directory on some distributions.

## Changes
 - Changed `Change_Variable` function to `Set_var`
 - Changed `Change_xml_variable` function to `Set_xml_var`
 - Various functions now return 0 or 1
 - Changed setup.sh and jellyman to use `Set_var`, `Set_xml_var`, and `Del_var`
 - Got rid of spaces instead of tabs throughout code
 - All prompts now begin with `>`, and all inputs should begin with `>>>`
 - `jellyman -i` now gives a list of backups to import
 - Changed jellyfin-backup.tar date code for better readability
 - Removed verbosity of import tar command
 - Removed verbosity of chmod and chown commands
 - Fixed import from overwriting the main jellyman bash program. (Potentially resulting in a previous version of Jellyman...)
 - `jellyman -bu` got a face-lift

# Jellyman v1.7.6
## Fixes
 - All prompts now follow the same format. Prevents most ways to break Jellyfin.
 - `jellyman -i` has been fixed.
 - Fixed enabling ports on firewallD going to the public zone instead of the current one.
 - Fixed `jellyman -X` blocking the default ports instead of the ports being used.
 - Fixed sed commands from duplicating files by changing all sed commands from `sed -i -e` to `sed -i`
 - Fixed input of linux user from allowing capital letters
 - Fixed `jellyman -ba` only deleting 1 backup if max number of backups has lowerd.

## Changes
 - Moved many of the functions to /usr/bin/base_functions.sh
 - Cleaned up more language and a typo.

# Jellyman v1.7.5
## Fixes
 - Has_sudo function has been replaced due to a SystemD error with the previous iteration.
 - Fixed error message in jellyman-backup.service
 - All input prompts for Jellyman has been made consistent
 **Example**
```
	Please enter the default user for Jellyfin
	>>> <INPUT>
```

# Jellyman v1.7.4
## Added
 - `jellyman -ba` performs an automatic backup
 - `jellyman -bu` starts the automatic backup setup utility
 
## Fixed
 - `jellyman -cp` Since Jellyfin 10.9, the variables have changed for http in config/networking.xml
 - `jellyman -cps` Since Jellyfin 10.9, the variables have changed for https in config/networking.xml
 - various language improvements.

# Jellyman v1.7.3
## Fixes

 - Fixed ubuntu systems failing to install because they lacked the `curl` package
 - Fixed issue with `jellyman -b` not allowing directories with spaces (You still must contain the directory with quotes) "path/to your/dir"
 - Fixed issue with `jellyman -cp` and `-cps` not changing the port.

# Jellyman v1.7.2
## Fixes

- Fixed /opt/jellyfin/jellyfin.sh not pointing to correct ffmpeg binary. (When did this change?!?!)
- Fixed various issues with `jellyman -h` and `man jellyman`
- Added `jellyman -U` to update the `/opt/jellyfin/jellyfin.sh` file

# Jellyman v1.7.1
## Fixes
- Fix for `jellyman -vd` regarding new repo site
- Fix for setup.sh regarding new repo site

From now on versions before 10.9.0 will not be supported as the versions are too different to go back after installing 10.9.0.

# Jellyman v1.7.0
## Fixes
 - Fixed setup.sh for new repo website
 - Fixed `jellyman -u` and `jellyman -ub` to use new websites
 
(please be patient as a lot has changed and some bugs may persist. There still needs to be testing and more elegant code to be written)

