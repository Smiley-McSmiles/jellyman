#!/bin/bash
DIRECTORY=$(cd `dirname $0` && pwd)
source $DIRECTORY/scripts/base_functions.sh
has_sudo_access=
architecture=
os_detected=
currentJellyfinDirectory=null
tarPath=
sourceFile=/opt/jellyfin/config/jellyman.conf

Import()
{
	Prompt_user file "> Please enter the path to the jellyfin-backup.tar archive." 0 0 "/path/to/backup.tar"
	importTar=$promptFile

	echo "+--------------------------------------------------------------------+"
	echo "|                        ******CAUTION******                         |"
	echo "|      This import procedurewill erase /opt/jellyfin COMPLETELY      |"
	echo "+--------------------------------------------------------------------+"

	if Prompt_user yN "> Import $importTar?"; then
		echo "> IMPORTING $importTar"
		jellyman -S
		rm -rf /opt/jellyfin
		tar xvf $importTar -C /
		clear
		source $sourceFile
		mv -f /opt/jellyfin/backup/jellyman /usr/bin/
		mv -f /opt/jellyfin/backup/base_functions.sh /usr/bin/
		chmod +rx /usr/bin/jellyman
		chmod +rx /usr/bin/base_functions.sh
		mv -f /opt/jellyfin/backup/*.service $jellyfinServiceLocation/
		mv -f /opt/jellyfin/backup/jellyfin-backup.timer $jellyfinServiceLocation/
		systemctl daemon-reload
		mv -f /opt/jellyfin/backup/jellyfin.conf /etc/
		if id $defaultUser &>/dev/null; then 
			chown -Rfv $defaultUser:$defaultUser /opt/jellyfin
			chmod -Rfv 770 /opt/jellyfin
			Install_dependancies
			jellyman -e -s
		else
			clear
			echo "+-----------------------------------------------------------------------------------------------+"
			echo "|                                     *******ERROR*******                                       |"
			echo "|          The imported default Jellyfin user($defaultUser) has not yet been created.           |"
			echo "|              This error is likely due to a read error of the $sourceFile file.                |"
			echo "| The default user is usually created by Jellyman - The Jellyfin Manager, when running setup.sh.|"
			echo "|                   You may want to see who owns that configuration file with:                  |"
			echo "|                          'ls -l /opt/jellyfin/config/jellyman.conf'                           |"
			echo "+-----------------------------------------------------------------------------------------------+"
			sleep 5
			if Prompt_user yN "> Would you like to create the LINUX user $defaultUser?"; then
				echo "> Great!"
				useradd -rd /opt/jellyfin $defaultUser
				chown -Rfv $defaultUser:$defaultUser /opt/jellyfin
				chmod -Rfv 770 /opt/jellyfin
				Install_dependancies
				jellyman -s -t
			else
				Prompt_user usr "> Please enter a new LINUX user" 0 0 "jellyfin"
				defaultUser=$promptUsr
		 
				defaultUser=${defaultUser,,}
				echo "> Linux user = $defaultUser"
				useradd -rd /opt/jellyfin $defaultUser
				
				chown -Rfv $defaultUser:$defaultUser /opt/jellyfin
				chmod -Rfv 770 /opt/jellyfin
				Install_dependancies
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
		ufw allow $httpPort/tcp
		ufw allow $httpsPort/tcp
		ufw reload
	elif [ -x "$(command -v firewall-cmd)" ]; then
		firewall-cmd --permanent --add-port=$httpPort/tcp
		firewall-cmd --permanent --add-port=$httpsPort/tcp
		firewall-cmd --reload
	else
		echo "+-------------------------------------------------------------------+"
		echo "|                        ******WARNING******                        |"
		echo "|                         ******ERROR******                         |"
		echo "|                  FAILED TO OPEN PORT $httpPort/$httpsPort!                   |"
		echo "|          ERROR NO 'ufw' OR 'firewall-cmd' COMMAND FOUND!          |"
		echo "+-------------------------------------------------------------------+"
	fi

	
	if Prompt_user Yn "> Would you like to remove the cloned git directory $DIRECTORY?"; then
		echo "> Removing cloned git directory:$DIRECTORY..."
		rm -rf $DIRECTORY
		cd ~/
	else
		echo "> Okay, keeping $DIRECTORY"
	fi
}

Get_Architecture()
{
	cpuArchitectureFull=$(uname -m)
		case "$cpuArchitectureFull" in
				x86_64)	architecture="amd64" ;;
				aarch64)  architecture="arm64" ;;
				armv*)	 architecture="armhf" ;;
				*)		  echo "ERROR UNKNOWN CPU ARCHITECTURE.. EXITING."
							 exit ;;
		esac
}

Install_dependancies()
{
	packagesNeededDebian='ffmpeg git net-tools openssl bc screen curl'
	packagesNeededRHEL='ffmpeg ffmpeg-devel ffmpeg-libs git openssl bc screen curl'
	packagesNeededArch='ffmpeg git openssl bc screen curl'
	packagesNeededOpenSuse='ffmpeg-4 git openssl bc screen curl'
	echo "> Preparing to install needed dependancies for Jellyfin..."

	if [ -f /etc/os-release ]; then
		source /etc/os-release
		crbOrPowertools=
		os_detected=true
		echo "> ID=$ID"
		
		if [[ $ID_LIKE == .*"rhel".* ]] || [[ $ID == "rhel" ]]; then
			ID=rhel
			
			if [[ $VERSION_ID == *"."* ]]; then
				VERSION_ID=$(echo $VERSION_ID | cut -d "." -f 1)
			fi
			
			if (( $VERSION_ID < 9 )); then
				crbOrPowertools="powertools"
			else
				crbOrPowertools="crb"
			fi
		fi
		
			case "$ID" in
				fedora)	dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
								dnf install $packagesNeededRHEL -y ;;
				rhel)		 dnf install epel-release -y
								dnf config-manager --set-enabled $crbOrPowertools
								dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm -y https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm -y
								dnf install $packagesNeededRHEL -y ;;
				debian)	apt install $packagesNeededDebian -y ;;
				ubuntu)	apt install $packagesNeededDebian -y ;;
				linuxmint) apt install $packagesNeededDebian -y ;;
				elementary) apt install $packagesNeededDebian -y ;;
				arch)		 pacman -Syu $packagesNeededArch ;;
				endeavouros) pacman -Syu $packagesNeededArch ;;
				manjaro)	 pacman -Syu $packagesNeededArch ;;
				opensuse*) zypper install $packagesNeededOpenSuse ;;
			esac
	else
		os_detected=false
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

Backup()
{
	backupDirectory=$1
	fileName=current-jellyfin-data.tar
	if [[ $(echo "${backupDirectory: -1}") == "/" ]]; then
		tarPath=$backupDirectory$fileName
		echo "> Saving your current metadata to --> $tarPath"
	else
		tarPath=$backupDirectory/$fileName
		echo "> Saving your current metadata to --> $tarPath"
	fi
	
	cd $currentJellyfinDirectory
	time tar cvf $tarPath data config
	USER=$(stat -c '%U' $backupDirectory)
	chown -f $USER:$USER $tarPath
	chmod -f 770 $tarPath
}


Previous_install()
{
	echo "> WARNING: THIS OPTION IS HIGHLY UNSTABLE, ONLY USE IF YOU KNOW WHAT YOU'RE DOING!!!"
	echo
	if Prompt_user yN "> Is Jellyfin CURRENTLY installed on this system?"; then
		isDataThere=false
		isConfigThere=false
		newDirectory=false
		Prompt_user dir "> Where is Jellyfins intalled directory?" 0 0 "/path/to/jellyfin/dir"
		currentJellyfinDirectory=$promptDir
		
		#systemFileXML=$(find $currentJellyfinDirectory -name "system.xml")
		#configPath=$(echo $systemFileXML | sed -r "s|/system.xml||g")
		#metadataPath=$(grep -o "<MetadataPath>.*" $systemFileXML | sed -r "s|<MetadataPath>||g" | sed -r "s|</MetadataPath>||g")
		#if [[ $configPath != *"config" ]]; then
		#	echo "'config' folder not found"
		#else
		#	
		#fi
		
		if [ ! -d "$currentJellyfinDirectory/data/metadata" ]; then
			echo "$currentJellyfinDirectory/data/metadata does not exist"
			isDataThere=false
		else
			isDataThere=true
			echo "> Found metadata!"
		fi

		if [ ! -d "$currentJellyfinDirectory/config" ]; then
			echo "$currentJellyfinDirectory/config does not exist"
			isConfigThere=false
		else
			isConfigThere=true
			echo "> Found config!"
		fi

		
		if ! $isDataThere || ! $isConfigThere; then
			echo "***ERROR*** - one or more directories not found..."
			if Prompt_user Yn "> Would you like to try a different directory?"; then
				currentJellyfinDirectory=null
			else
				exit
			fi
		fi
		
		Backup $HOME
		cd /opt/jellyfin
		tar xvf $tarPath -C ./
	else
		echo "> Good call.."
	fi
}

Setup()
{
	echo "> Fetching newest stable Jellyfin version..."
	Get_Architecture
	jellyfin=
	jellyfin_archive=
	
	if [ ! -f *"tar.gz" ]; then
		jellyfin_archive=$(curl -sL https://repo.jellyfin.org/files/server/linux/latest-stable/$architecture/ | grep -Po jellyfin_[^_]+-$architecture.tar.gz | head -1)	
		wget https://repo.jellyfin.org/files/server/linux/latest-stable/$architecture/$jellyfin_archive
		jellyfin=$(echo $jellyfin_archive | sed -r "s|-$architecture.tar.gz||g")
	else
		jellyfin_archive=$(ls *.tar.gz)
		jellyfin=$(echo $jellyfin_archive | sed -r "s|-$architecture.tar.gz||g")
	fi
	
	mkdir /opt/jellyfin /opt/jellyfin/old /opt/jellyfin/backup /opt/jellyfin/data /opt/jellyfin/cache /opt/jellyfin/config /opt/jellyfin/log /opt/jellyfin/cert
	clear
	Previous_install
	Prompt_user usr "> Please enter the LINUX user for Jellyfin" 0 0 "jellyfin"
	defaultUser=$promptUsr
	while id "$defaultUser" &>/dev/null; do
		echo "> Cannot create $defaultUser as $defaultUser already exists..."
		Prompt_user usr "> Please re-enter a new LINUX user for Jellyfin"
		defaultUser=$promptUsr
	done
	
	defaultUser=${defaultUser,,}
	echo "> Linux user = $defaultUser"
	useradd -rd /opt/jellyfin $defaultUser

	if [ -x "$(command -v apt)" ] || [ -x "$(command -v pacman)" ]; then
		cp $DIRECTORY/jellyman.1 /usr/share/man/man1/
	elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v zypper)" ]; then 
		cp $DIRECTORY/jellyman.1 /usr/local/share/man/man1/
	fi

	cp $DIRECTORY/scripts/jellyman /usr/bin/
	cp $DIRECTORY/scripts/base_functions.sh /usr/bin/
	chmod +rx /usr/bin/base_functions.sh
	cp $DIRECTORY/scripts/jellyfin.sh /opt/jellyfin/
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
	
	Set_var User "$defaultUser" "$jellyfinServiceLocation/jellyfin.service" str
	cp $DIRECTORY/conf/jellyfin.conf /etc/
	jellyfinDir=/opt/jellyfin
	jellyfinConfigFile=$jellyfinDir/config/jellyman.conf
	tar xvzf $DIRECTORY/$jellyfin_archive
	mv -f $DIRECTORY/jellyfin /opt/jellyfin/$jellyfin
	ln -s $jellyfinDir/$jellyfin $jellyfinDir/jellyfin
	Set_var architecture "$architecture" "$jellyfinConfigFile" str
	Set_var httpPort "8096" "$jellyfinConfigFile" str
	Set_var httpsPort "8920" "$jellyfinConfigFile" str
	Set_var currentVersion "$jellyfin" "$jellyfinConfigFile" str
	Set_var defaultUser "$defaultUser" "$jellyfinConfigFile" str
	Set_var jellyfinServiceLocation "$jellyfinServiceLocation" "$jellyfinConfigFile" str

	Install_dependancies

	echo "> Setting Permissions for Jellyfin..."
	chown -R $defaultUser:$defaultUser /opt/jellyfin
	chmod u+x $jellyfinDir/jellyfin.sh
	chmod +rx /usr/bin/jellyman

	echo "> Unblocking port 8096 and 8920..."
	if [ -x "$(command -v ufw)" ]; then
		ufw allow 8096/tcp
		ufw allow 8920/tcp
		ufw reload
	elif [ -x "$(command -v firewall-cmd)" ]; then
		firewall-cmd --permanent --zone=public --add-port=8096/tcp
		firewall-cmd --permanent --zone=public --add-port=8920/tcp
		firewall-cmd --reload
	else
		echo "+-------------------------------------------------------------------+"
		echo "|                        ******WARNING******                        |"
		echo "|                         ******ERROR******                         |"
		echo "|                  FAILED TO OPEN PORT 8096/8920!                   |"
		echo "|          ERROR NO 'ufw' OR 'firewall-cmd' COMMAND FOUND!          |"
		echo "+-------------------------------------------------------------------+"
	fi

	if $os_detected; then
		jellyman -e -s
		echo
		echo
		echo "> DONE"
		echo
		echo "+-------------------------------------------------------------------+"
		echo "|                 Navigate to http://localhost:8096/                |"
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
	if Prompt_user Yn "> Would you like to remove the cloned git directory $DIRECTORY?"; then
		echo "> Removing cloned git directory:$DIRECTORY..."
		rm -rf $DIRECTORY
		cd ~/
	else
		echo "> Okay, keeping $DIRECTORY"
	fi
}

Update_jellyman()
{
	source $sourceFile
	echo "> Updating Jellyman - The Jellyfin Manager"
	cp -f $DIRECTORY/scripts/jellyman /usr/bin/jellyman
	cp -f $DIRECTORY/scripts/jellyfin.sh /opt/jellyfin/jellyfin.sh
	chmod +rx /usr/bin/jellyman
	cp $DIRECTORY/conf/jellyfin.service /usr/lib/systemd/system/
	cp $DIRECTORY/scripts/base_functions.sh /usr/bin/
	chmod +rx /usr/bin/base_functions.sh
	
	# deletes all empty lines in $sourcefile
	sed -i '/^ *$/d' $sourceFile
	

	if [[ ! -f $jellyfinServiceLocation/jellyfin-backup.timer ]]; then
		cp $DIRECTORY/conf/jellyfin-backup.service /usr/lib/systemd/system/
		cp $DIRECTORY/conf/jellyfin-backup.timer /usr/lib/systemd/system/
	fi
	
	Set_var User "$defaultUser" "$jellyfinServiceLocation/jellyfin.service" str
	
	if [ -x "$(command -v apt)" ] || [ -x "$(command -v pacman)" ]; then
		cp $DIRECTORY/jellyman.1 /usr/share/man/man1/
	elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v zypper)" ]; then 
		cp $DIRECTORY/jellyman.1 /usr/local/share/man/man1/
	fi
	
	if ( ! grep -q httpPort= "$sourceFile" ) || ( ! grep -q httpsPort= "$sourceFile" ); then
		Set_var httpPort "8096" "$sourceFile" str
		Set_var httpsPort "8920" "$sourceFile" str
	fi
	
	Del_var networkPort $sourceFile
	
	if [[ -d /usr/lib/systemd ]] && [[ ! -n $jellyfinServiceLocation ]]; then
		jellyfinServiceLocation="/usr/lib/systemd/system"
		Set_var jellyfinServiceLocation "$jellyfinServiceLocation" "$sourceFile" str
	elif [[ ! -n $jellyfinServiceLocation ]]; then
		jellyfinServiceLocation="/etc/systemd/system"
		Set_var jellyfinServiceLocation "$jellyfinServiceLocation" "$sourceFile" str
	fi

	
	if [[ ! -n $architecture ]]; then
		architecture=
		Get_Architecture
		Set_var architecture "$architecture" "$sourceFile" str
	fi


	if Prompt_user Yn "> Would you like to remove the cloned git directory $DIRECTORY?"; then
		echo "> Removing cloned git directory:$DIRECTORY..."
		rm -rf $DIRECTORY
		cd ~/
	else
		echo "> Okay, keeping $DIRECTORY"
	fi
	echo "> ...complete"
	
}

Has_sudo
optionNumber=

if [[ $1 == "-U" ]]; then
	Update_jellyman
else
	while [[ ! -n $optionNumber ]]; do
		echo "1. Start first time setup"
		echo "2. Force update Jellyman"
		echo "3. Import a jellyfin-backup.tar file"
		echo
		Prompt_user num "> Please select the number corresponding with the option you want to select." 1 3 "1-3"
		optionNumber=$promptNum
		echo
	done

	case "$optionNumber" in
		1)	Setup ;;
		2)	Update_jellyman ;;
		3)	Import;;
	esac
fi
