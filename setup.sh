#!/bin/bash
DIRECTORY=$(cd `dirname $0` && pwd)
source $DIRECTORY/scripts/jellyman-functions
hasSudoAccess=
architecture=
osDetected=
currentJellyfinDirectory=null
tarPath=
sourceFile=/opt/jellyfin/config/jellyman.conf

Import(){
	logFile=/tmp/jellyman_import.log
	touch $logFile
	PromptUser dir "> Please enter the directory to the jellyfin-backup.tar archive(s)." 0 0 "/path/to/backup(s)"
	importDir=$promptResult
	Log "IMPORT | importDir=$promptResult" $logFile
	listOfBackups=$(ls -1 $importDir | grep "jellyfin-backup".*".tar")
	listOfBackupsNumbered=$(echo "$listOfBackups" | cat -n)
	numberOfBackups=$(echo "$listOfBackups" | wc -l)
	echo "$listOfBackupsNumbered"
	PromptUser num "> Please enter the number corresponding with the archive you wish to import." 1 $numberOfBackups "1-$numberOfBackups"
	backupToImportNumber=$promptResult
	backupToImport=$(echo "$listOfBackups" | head -n $backupToImportNumber | tail -n 1)
	importTar="$importDir/$backupToImport"
	Log "IMPORT | importTar=$importDir/$backupToImport" $logFile
	jellyfinServiceLocation=

	echo "+--------------------------------------------------------------------+"
	echo "|                        ******CAUTION******                         |"
	echo "|      This import procedure will erase /opt/jellyfin COMPLETELY      |"
	echo "+--------------------------------------------------------------------+"

	if PromptUser yN "> Import $importTar?"; then
		echo "> IMPORTING $importTar"
		
		if [[ -d /opt/jellyfin ]]; then
			rm -rf /opt/jellyfin
			Log "IMPORT | Removed /opt/jellyfin" $logFile
		fi
		
		tar xf $importTar -C /
		source $sourceFile
		mv -f $logFile /opt/jellyfin/log/
		logFile=/opt/jellyfin/log/jellyman_import.log
		mv -f /opt/jellyfin/backup/jellyfin.conf /etc/
		cp -f $DIRECTORY/scripts/jellyman /usr/bin/
		cp -f $DIRECTORY/scripts/jellyman-functions /usr/bin/
		chmod +rx /usr/bin/jellyman
		chmod +rx /usr/bin/jellyman-functions
		
		if [ -d /usr/lib/systemd/system ]; then
			jellyfinServiceLocation="/usr/lib/systemd/system"
			SetVar jellyfinServiceLocation $jellyfinServiceLocation "$sourceFile" str
			mv -f /opt/jellyfin/backup/*.service $jellyfinServiceLocation/
			mv -f /opt/jellyfin/backup/jellyfin-backup.timer $jellyfinServiceLocation/
		else
			jellyfinServiceLocation="/etc/systemd/system"
			SetVar jellyfinServiceLocation $jellyfinServiceLocation "$sourceFile" str
			mv -f /opt/jellyfin/backup/*.service /etc/systemd/system/
			mv -f /opt/jellyfin/backup/jellyfin-backup.timer /etc/systemd/system/
		fi
		Log "IMPORT | SetVar jellyfinServiceLocation=$jellyfinServiceLocation" $logFile
		
		systemctl daemon-reload
		
		if [[ -n $autoBackups ]] && $autoBackups; then
			systemctl enable --now jellyfin-backup.timer
		else
			if PromptUser Yn "Enable automatic backups?" 0 0 "Y/n"; then
				systemctl enable --now jellyfin-backup.timer
				SetVar autoBackups true "$sourceFile" str
				SetVar "backupFrequency" "weekly" "$sourceFile"
			else
				systemctl enable --now jellyfin-backup.timer
				SetVar autoBackups false "$sourceFile" str
				SetVar "backupFrequency" "weekly" "$sourceFile"
			fi
		fi
		
		if id $defaultUser &>/dev/null; then 
			chown -Rf $defaultUser:$defaultUser /opt/jellyfin
			chmod -Rf 770 /opt/jellyfin
			InstallDependencies
			jellyman -e -s
			echo "> IMPORT COMPLETE!"
			Log "IMPORT | Complete!" $logFile
		else
			echo
			echo "> The imported LINUX user for Jellyfin has not yet been created."
			if PromptUser yN "> Would you like to create the imported LINUX user $defaultUser?"; then
				echo "> Creating LINUX user $defaultUser"
				useradd -rd /opt/jellyfin $defaultUser
				Log "IMPORT | Useradd $defaultUser" $logFile
				usermod -aG video $defaultUser
				usermod -aG render $defaultUser

				chown -Rf $defaultUser:$defaultUser /opt/jellyfin
				chmod -Rf 770 /opt/jellyfin
				SetVar User "$defaultUser" "$jellyfinServiceLocation/jellyfin.service" null
				InstallDependencies
				jellyman -e -s -t
			else
				PromptUser usr "> Please enter a new LINUX user." 0 0 "jellyfin"
				defaultUser=$promptResult
				while id "$defaultUser" &>/dev/null; do
					echo "> Cannot create $defaultUser as $defaultUser already exists..."
					PromptUser usr "> Please re-enter a new default LINUX user for Jellyfin"
					defaultUser=$promptResult
					Log "ERROR | IMPORT | USERADD FAILED $defaultUser ALREADY EXISTS" $logFile
				done

				echo "> LINUX user = $defaultUser"
				useradd -rd /opt/jellyfin $defaultUser
				usermod -aG video $defaultUser
				usermod -aG render $defaultUser
				Log "IMPORT | Useradd $defaultUser" $logFile
				chown -Rf $defaultUser:$defaultUser /opt/jellyfin
				chmod -Rf 770 /opt/jellyfin
				InstallDependencies
				SetVar User "$defaultUser" "$jellyfinServiceLocation/jellyfin.service" null
				jellyman -e -s -t
			fi
		fi

	else
		echo "> Returning..."
		return 0
		exit
	fi

	echo "> Unblocking port $httpPort and $httpsPort..."
	if [ -x "$(command -v ufw)" ]; then
		Log "IMPORT | Using ufw to unblock $httpPort AND $httpsPort" $logFile
		ufw allow $httpPort/tcp
		ufw allow $httpsPort/tcp
		ufw reload
	elif [ -x "$(command -v firewall-cmd)" ]; then
		Log "IMPORT | Using firewalld to unblock $httpPort AND $httpsPort" $logFile
		firewall-cmd --permanent --add-port=$httpPort/tcp
		firewall-cmd --permanent --add-port=$httpsPort/tcp
		firewall-cmd --reload
	else
		Log "ERROR | IMPORT | UNABLE TO FIND UFW OR FIREWALLD" $logFile
		echo "+-------------------------------------------------------------------+"
		echo "|                        ******WARNING******                        |"
		echo "|                         ******ERROR******                         |"
		echo "|                  FAILED TO OPEN PORT $httpPort/$httpsPort!                   |"
		echo "|          ERROR NO 'ufw' OR 'firewall-cmd' COMMAND FOUND!          |"
		echo "+-------------------------------------------------------------------+"
	fi
	
	if PromptUser Yn "> Would you like to remove the cloned git directory $DIRECTORY?"; then
		echo "> Removing cloned git directory: $DIRECTORY..."
		rm -rf $DIRECTORY
	else
		echo "> Okay, keeping $DIRECTORY"
	fi
}

GetArchitecture(){
	cpuArchitectureFull=$(uname -m)
		case "$cpuArchitectureFull" in
				x86_64) architecture="amd64" ;;
				aarch64) architecture="arm64" ;;
				armv*) architecture="armhf" ;;
				*) echo "ERROR UNKNOWN CPU ARCHITECTURE.. EXITING."
					exit ;;
		esac
}

InstallDependencies(){
	packagesNeededDebian=(libva libva2 mesa-va-drivers mesa-vdpau-drivers ffmpeg git net-tools openssl bc screen curl wget tar)
    packagesNeededRHEL=(libva libva-utils libva-vdpau-driver libva-intel-media-driver libva-intel-driver libva-nvidia-driver mesa-va-drivers mesa-vdpau-drivers ffmpeg ffmpeg-devel ffmpeg-libs libicu git openssl bc screen curl wget tar)
    packagesNeededArch=(libva-utils libva-nvidia-driver libva-intel-driver libva-mesa-driver vulkan-radeon ffmpeg git openssl bc screen curl wget tar)
    packagesNeededOpenSuse=(libva libva2 mesa-libva libva-utils libva-vdpau-driver mesa-libva mesa-gallium mesa-drivers ffmpeg-4 git openssl bc screen curl wget tar)
    echo "> Preparing to install needed dependancies for Jellyfin and Jellyman..."

	if [ -f /etc/os-release ]; then
		source /etc/os-release
		crbOrPowertools=
		osDetected=true
		echo "> ID=$ID"
		
		if [[ $ID_LIKE =~ "rhel" ]] || [[ $ID == "rhel" ]]; then
			ID=rhel
			
			if [[ $VERSION_ID == *"."* ]]; then
				VERSION_ID=$(echo $VERSION_ID | cut -d "." -f 1)
			fi
			
			if (( $VERSION_ID < 9 )); then
				crbOrPowertools="powertools"
			else
				packagesRemoved=(libva-vdpau-driver libva-intel-media-driver libva-nvidia-driver mesa-va-drivers mesa-vdpau-drivers)
				echo "> RHEL 9 detected, removing unavailable packages: $packagesRemoved"
				echo "> Please compile from source VAAPI drivers to take advantage of hardware acceleration"
				for pkg in ${packagesRemoved[@]}; do
					packagesNeededRHEL=("${packagesNeededRHEL[@]/$pkg}")
				done
				crbOrPowertools="crb"
			fi
		fi
		
			case "$ID" in
				fedora)
					dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
					dnf install "${packagesNeededRHEL[@]}" -y
					sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
					sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld ;;
				rhel)
					dnf install epel-release -y
					dnf config-manager --set-enabled $crbOrPowertools
					dnf install --nogpgcheck https://mirrors.trpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm \
					https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm -y
					dnf install "${packagesNeededRHEL[@]}" -y ;;
				debian | ubuntu | linuxmint | elementary)
					apt install "${packagesNeededDebian[@]}" -y ;;
				arch | endeavouros | manjaro)
					pacman -Syu "${packagesNeededArch[@]}" ;;
				opensuse*)
					zypper install "${packagesNeededOpenSuse[@]}" ;;
			esac
	else
		osDetected=false
		echo "+-------------------------------------------------------------------+"
		echo "|                       ******WARNING******                         |"
		echo "|                        ******ERROR******                          |"
		echo "|               FAILED TO FIND /etc/os-release FILE.                |"
		echo "|              PLEASE MANUALLY INSTALL THESE PACKAGES:              |"
		echo "|                     ffmpeg git AND openssl                        |"
		echo "+-------------------------------------------------------------------+"
		
		read -p "Press ENTER to continue" ENTER
	fi
}

InstallJellyfinFfmpeg(){
	logFile=$1
	GetArchitecture
	echo "> Fetching newest jellyfin-ffmpeg archive..."
	jellyfinFfmpegRepo="https://repo.jellyfin.org/files/ffmpeg/linux/latest-6.x/$architecture"
	jellyfinFfmpegArchive=$(curl -fsSL "https://repo.jellyfin.org/?path=/ffmpeg/linux/latest-6.x/$architecture" | grep -o "jellyfin".*".tar.xz" | head -n 1 | cut -d"'" -f1)
	mkdir /usr/lib/jellyfin-ffmpeg
	wget -O jellyfin-ffmpeg.tar.xz "$jellyfinFfmpegRepo/$jellyfinFfmpegArchive"
	tar xf jellyfin-ffmpeg*.tar.xz -C /usr/lib/jellyfin-ffmpeg/
	SetVar FFMPEGDIR "/usr/lib/jellyfin-ffmpeg/ffmpeg" "/opt/jellyfin/jellyfin.sh" str
	Log "JELLYFIN-FFMPEG | Downloaded $jellyfinFfmpegRepo/$jellyfinFfmpegArchive" $logFile
}

Setup(){
	logFile=/tmp/jellyman_setup.log

	echo "> Installing dependencies..."
	InstallDependencies

	echo "> Fetching newest stable Jellyfin version..."
	GetArchitecture
	jellyfin=
	jellyfin_archive=
	
	if [ ! -f *"tar.gz" ]; then
		jellyfin_archive=$(curl -sL https://repo.jellyfin.org/files/server/linux/latest-stable/$architecture/ | grep -Po jellyfin_[^_]+-$architecture.tar.gz | head -1)	
		wget https://repo.jellyfin.org/files/server/linux/latest-stable/$architecture/$jellyfin_archive
		jellyfin=$(echo $jellyfin_archive | sed -r "s|-$architecture.tar.gz||g")
		Log "SETUP | Downloaded https://repo.jellyfin.org/files/server/linux/latest-stable/$architecture/$jellyfin_archive" $logFile
	else
		jellyfin_archive=$(ls *.tar.gz)
		jellyfin=$(echo $jellyfin_archive | sed -r "s|-$architecture.tar.gz||g")
		Log "SETUP | Using local $jellyfin_archive" $logFile
	fi
	
	mkdir /opt/jellyfin /opt/jellyfin/old /opt/jellyfin/backup /opt/jellyfin/data /opt/jellyfin/cache /opt/jellyfin/config /opt/jellyfin/log /opt/jellyfin/cert
	mv $logFile /opt/jellyfin/log
	logFile=/opt/jellyfin/log/jellyman_setup.log
	clear
	PromptUser usr "> Please enter the LINUX user for Jellyfin" 0 0 "jellyfin"
	defaultUser=$promptResult
	while id "$defaultUser" &>/dev/null; do
		echo "> Cannot create $defaultUser as $defaultUser already exists..."
		PromptUser usr "> Please re-enter a new LINUX user for Jellyfin"
		defaultUser=$promptResult
	done
	
	echo "> Linux user = $defaultUser"
	useradd -rd /opt/jellyfin $defaultUser
	Log "SETUP | Created user $defaultUser" $logFile
	usermod -aG video $defaultUser
	usermod -aG render $defaultUser

	if [ -x "$(command -v apt)" ] || [ -x "$(command -v pacman)" ]; then
		cp $DIRECTORY/jellyman.1 /usr/share/man/man1/
	elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v zypper)" ]; then 
		cp $DIRECTORY/jellyman.1 /usr/local/share/man/man1/
	fi

	cp $DIRECTORY/scripts/jellyman /usr/bin/
	cp $DIRECTORY/scripts/jellyman-functions /usr/bin/
	chmod +rx /usr/bin/jellyman-functions
	cp $DIRECTORY/scripts/jellyfin.sh /opt/jellyfin/
	InstallJellyfinFfmpeg "$logFile"
	touch $sourceFile
	jellyfinServiceLocation=
	
	if [ -d /usr/lib/systemd/system ]; then
		cp $DIRECTORY/conf/jellyfin.service /usr/lib/systemd/system/
		cp $DIRECTORY/conf/jellyfin-backup* /usr/lib/systemd/system/
		jellyfinServiceLocation="/usr/lib/systemd/system"
	else
		cp $DIRECTORY/conf/jellyfin.service /etc/systemd/system/
		cp $DIRECTORY/conf/jellyfin-backup* /etc/systemd/system/
		jellyfinServiceLocation="/etc/systemd/system"
	fi
	Log "SETUP | SetVar jellyfinServiceLocation=$jellyfinServiceLocation" $logFile
	
	SetVar User "$defaultUser" "$jellyfinServiceLocation/jellyfin.service" null
	Log "SETUP | SetVar User to $defaultUser in $jellyfinServiceLocation/jellyfin.service" $logFile
	cp $DIRECTORY/conf/jellyfin.conf /etc/
	jellyfinDir=/opt/jellyfin
	jellyfinConfigFile=$jellyfinDir/config/jellyman.conf
	echo "> Unpacking $DIRECTORY/$jellyfin_archive..."
	tar xzf $DIRECTORY/$jellyfin_archive
	mv -f $DIRECTORY/jellyfin /opt/jellyfin/$jellyfin
	ln -s $jellyfinDir/$jellyfin $jellyfinDir/jellyfin
	SetVar architecture "$architecture" "$jellyfinConfigFile" str
	SetVar httpPort "8096" "$jellyfinConfigFile" str
	SetVar httpsPort "8920" "$jellyfinConfigFile" str
	SetVar currentVersion "$jellyfin" "$jellyfinConfigFile" str
	SetVar defaultUser "$defaultUser" "$jellyfinConfigFile" str
	SetVar jellyfinServiceLocation "$jellyfinServiceLocation" "$jellyfinConfigFile" str
	Log "SETUP | SetVar $architecture 8096 8920 $jellyfin $defaultUser $jellyfinServiceLocation" $logFile

	echo "> Setting Permissions for Jellyfin..."
	chown -R $defaultUser:$defaultUser /opt/jellyfin
	chmod +x $jellyfinDir/jellyfin.sh
	chmod +rx /usr/bin/jellyman

	echo "> Unblocking port 8096 and 8920..."
	if [ -x "$(command -v ufw)" ]; then
		ufw allow 8096/tcp
		ufw allow 8920/tcp
		ufw reload
		Log "SETUP | Used ufw to allow ports 8096 and 8920" $logFile
	elif [ -x "$(command -v firewall-cmd)" ]; then
		firewall-cmd --permanent --add-port=8096/tcp
		firewall-cmd --permanent --add-port=8920/tcp
		firewall-cmd --reload
		Log "SETUP | Used firewalld to allow ports 8096 and 8920" $logFile
	else
		Log "ERROR | SETUP | FAILED TO OPEN PORT 8096/8920! NO UFW OR FIREWALLD FOUND" $logFile
		echo "+-------------------------------------------------------------------+"
		echo "|                        ******WARNING******                        |"
		echo "|                         ******ERROR******                         |"
		echo "|                  FAILED TO OPEN PORT 8096/8920!                   |"
		echo "|          ERROR NO 'ufw' OR 'firewall-cmd' COMMAND FOUND!          |"
		echo "+-------------------------------------------------------------------+"
	fi

	if $osDetected; then
		Log "SETUP | DONE" $logFile
		jellyman -e -s
		echo
		echo
		echo "> DONE"
		echo
		echo "+-------------------------------------------------------------------+"
		echo "|      Navigate to http://localhost:8096/web/#/wizardstart.html     |"
		echo "|         in your Web Browser to claim your Jellyfin server         |"
		echo "+-------------------------------------------------------------------+"
		echo
		echo "+-------------------------------------------------------------------+"
		echo "|         To enable https please enter 'sudo jellyman -rc'          |"
		echo "|       (After you have navigated to the Jellyfin Dashboard)        |"
		echo "|                                                                   |"
		echo "|                To manage Jellyfin use 'jellyman -h'               |"
		echo "+-------------------------------------------------------------------+"
		echo
		read -p "Press ENTER to continue" ENTER
		jellyman -h
	else
		Log "ERROR | SETUP | NO /etc/os-release FILE!" $logFile
		jellyman -h 
		echo "+-------------------------------------------------------------------+"
		echo "|                        ******WARNING******                        |"
		echo "|            JELLYFIN MEDIA SERVER NOT ENABLED OR STARTED           |"
		echo "|               FAILED TO FIND /etc/os-release FILE.                |"
		echo "|             PLEASE MANUALLY INSTALL THESE PACKAGES:               |"
		echo "|                     ffmpeg git AND openssl                        |"
		echo "|       THEN RUN: jellyman -e -s TO ENABLE AND START JELLYFIN       |"
		echo "+-------------------------------------------------------------------+"
	fi
	echo
	echo "> Press 'q' to exit next screen"
	read -p "> Press ENTER to continue" ENTER
	jellyman -t
	echo
	if PromptUser Yn "> Would you like to remove the cloned git directory $DIRECTORY?"; then
		echo "> Removing cloned git directory: $DIRECTORY..."
		rm -rf $DIRECTORY
	else
		echo "> Okay, keeping $DIRECTORY"
	fi
}

Update_jellyman(){
	logFile=/opt/jellyfin/log/jellyman_update.log

	if [[ ! -f /usr/bin/jellyman ]]; then
		logFile=/tmp/jellyman_update.log
		Log "ERROR | UPDATE | JELLYMAN NOT INSTALLED" $logFile
		echo "> ERROR: JELLYMAN IS NOT INSTALLED, CANNOT UPDATE."
		echo "> Please run 'sudo ./setup.sh' and choose option #1" 
		return 1
		exit
	fi

	if [[ ! -d /usr/lib/jellyfin-ffmpeg ]]; then
		InstallJellyfinFfmpeg "$logFile"
	fi

	_skip=$1
	source $sourceFile
	echo "> Updating Jellyman - The Jellyfin Manager"
	Log "UPDATE | Jellyman started update" $logFile
	cp -f $DIRECTORY/scripts/jellyman /usr/bin/jellyman
	chmod +rx /usr/bin/jellyman
	cp $DIRECTORY/scripts/jellyman-functions /usr/bin/
	chmod +rx /usr/bin/jellyman-functions
	
	# deletes all empty lines in $sourcefile
	sed -i '/^ *$/d' $sourceFile
	
	SetVar User "$defaultUser" "$jellyfinServiceLocation/jellyfin.service" null
	
	if [ -x "$(command -v apt)" ] || [ -x "$(command -v pacman)" ]; then
		cp $DIRECTORY/jellyman.1 /usr/share/man/man1/
	elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v zypper)" ]; then 
		cp $DIRECTORY/jellyman.1 /usr/local/share/man/man1/
	fi
	
	if ( ! grep -q httpPort= "$sourceFile" ) || ( ! grep -q httpsPort= "$sourceFile" ); then
		SetVar httpPort "8096" "$sourceFile" null
		SetVar httpsPort "8920" "$sourceFile" null
	fi
	
	DelVar networkPort $sourceFile
	
	if [[ -d /usr/lib/systemd ]] && [[ ! -n $jellyfinServiceLocation ]]; then
		jellyfinServiceLocation="/usr/lib/systemd/system"
		SetVar jellyfinServiceLocation "$jellyfinServiceLocation" "$sourceFile" str
	elif [[ ! -n $jellyfinServiceLocation ]]; then
		jellyfinServiceLocation="/etc/systemd/system"
		SetVar jellyfinServiceLocation "$jellyfinServiceLocation" "$sourceFile" str
	fi
	
	cp $DIRECTORY/conf/jellyfin.service $jellyfinServiceLocation/
	if [[ ! -f $jellyfinServiceLocation/jellyfin-backup.timer ]]; then
		cp $DIRECTORY/conf/jellyfin-backup.service $jellyfinServiceLocation/
		cp $DIRECTORY/conf/jellyfin-backup.timer $jellyfinServiceLocation/
	fi
	
	systemctl daemon-reload
	
	if [[ ! -n $architecture ]]; then
		architecture=
		GetArchitecture
		SetVar architecture "$architecture" "$sourceFile" str
	fi

	if [[ -f /usr/bin/base_functions.sh ]]; then
		rm -f /usr/bin/base_functions.sh
	fi

	if [[ $_skip == "y" ]]; then
		echo "> Removing cloned git directory: $DIRECTORY..."
		rm -rf $DIRECTORY
	else
		if PromptUser Yn "> Would you like to remove the cloned git directory $DIRECTORY?"; then
			echo "> Removing cloned git directory: $DIRECTORY..."
			rm -rf $DIRECTORY
		else
			echo "> Okay, keeping $DIRECTORY"
		fi
	fi
	echo "> ...complete"
	Log "UPDATE | Jellyman finished update" $logFile
}

HasSudo
optionNumber=

if [[ $1 == "-U" ]]; then
	Update_jellyman y
else
	while [[ ! -n $optionNumber ]]; do
		echo "1. Start first time setup"
		echo "2. Force update Jellyman"
		echo "3. Import a jellyfin-backup.tar file"
		echo
		PromptUser num "> Please select the number corresponding with the option you want to select." 1 3 "1-3"
		optionNumber=$promptResult
		echo
	done

	case "$optionNumber" in
		1)	Setup ;;
		2)	Update_jellyman ;;
		3)	Import;;
	esac
fi
