#!/bin/bash
DIRECTORY=$(cd `dirname $0` && pwd)
has_sudo_access=
architecture=
os_detected=
currentJellyfinDirectory=null
tarPath=

Has_sudo()
{
	has_sudo_access=""
	`timeout -k .1 .1 bash -c "sudo /bin/chmod --help" >&/dev/null 2>&1` >/dev/null 2>&1
	if [ $? -eq 0 ];then
		has_sudo_access="YES"
	else
		has_sudo_access="NO"
		echo "$USER, you're not using sudo..."
		echo "Please use 'sudo ./setup.sh' to install Jellyfin and Jellyman."
		exit
	fi
}

Import()
{
	importTar=
	while [[ ! -f $importTar ]]; do
		echo "Please enter the path to the jellyfin-backup.tar archive."
		read -p ">>> " importTar
	done
	
	echo "+--------------------------------------------------------------------+"
	echo "|                        ******WARNING******                         |"
	echo "|                        ******CAUTION******                         |"
	echo "| This procedure should only be used as a fresh install of Jellyfin. |"
	echo "|       As this procedure will erase /opt/jellyfin COMPLETELY        |"
	echo "+--------------------------------------------------------------------+"

	read -p "...Continue? [yes/No] : " importOrNotToImport
	if [[ $importOrNotToImport == [yY][eE][sS] ]] || [[ $importOrNotToImport == [yY] ]]; then
		echo "IMPORTING $importTar"
		jellyman -S
		rm -rf /opt/jellyfin
		tar xvf $importTar -C /
		clear
		source /opt/jellyfin/config/jellyman.conf
		mv -f /opt/jellyfin/backup/jellyman /usr/bin/
		chmod +rx /usr/bin/jellyman
		mv -f /opt/jellyfin/backup/*.service $jellyfinServiceLocation/
		mv -f /opt/jellyfin/backup/jellyfin-backup.timer $jellyfinServiceLocation/
		mv -f /opt/jellyfin/backup/jellyfin.conf /etc/
		if id "$defaultUser" &>/dev/null; then 
			chown -Rfv $defaultUser:$defaultUser /opt/jellyfin
			chmod -Rfv 770 /opt/jellyfin
			Install_dependancies
			jellyman -e -s -t
		else
			clear
			echo "+-----------------------------------------------------------------------------------------------+"
			echo "|                                     ******WARNING******                                       |"
			echo "|                                     *******ERROR*******                                       |"
			echo "|          The imported default Jellyfin user($defaultUser) has not yet been created.           |"
			echo "|    This error is likely due to a read error of the /opt/jellyfin/config/jellyman.conf file.   |"
			echo "| The default user is usually created by Jellyman - The Jellyfin Manager, when running setup.sh.|"
			echo "|                   You may want to see who owns that configuration file with:                  |"
			echo "|                          'ls -l /opt/jellyfin/config/jellyman.conf'                           |"
			echo "+-----------------------------------------------------------------------------------------------+"
			sleep 5
			read -p "...Create user $defaultUser? [yes/No] : " newUserOrOld
			if [[ $newUserOrOld == [yY][eE][sS] ]] || [[ $newUserOrOld == [yY] ]]; then
				echo "Great!"
				sleep .5
				useradd -rd /opt/jellyfin $defaultUser
				chown -Rfv $defaultUser:$defaultUser /opt/jellyfin
				chmod -Rfv 770 /opt/jellyfin
				Install_dependancies
				jellyman -s -t
			else
				read -p "Please enter a new Linux user: " defaultUser
				while id "$defaultUser" &>/dev/null; do
					  echo "Cannot create $defaultUser as $defaultUser already exists..."
					  read -p "Please re-enter a new default Linux user for Jellyfin: " defaultUser
				 done
		 
				defaultUser=${defaultUser,,}
				echo "Linux user = $defaultUser"
				useradd -rd /opt/jellyfin $defaultUser
				
				chown -Rfv $defaultUser:$defaultUser /opt/jellyfin
				chmod -Rfv 770 /opt/jellyfin
				Install_dependancies
				jellyman -e -s -t
			fi
		fi

	else
		echo "Returning..."
	fi

	echo "Unblocking port $httpPort and $httpsPort..."
	if [ -x "$(command -v ufw)" ]; then
		ufw allow $httpPort/tcp
		ufw allow $httpsPort/tcp
		ufw reload
	elif [ -x "$(command -v firewall-cmd)" ]; then
		firewall-cmd --permanent --zone=public --add-port=$httpPort/tcp
		firewall-cmd --permanent --zone=public --add-port=$httpsPort/tcp
		firewall-cmd --reload
	else
		echo "+-------------------------------------------------------------------+"
		echo "|                        ******WARNING******                        |"
		echo "|                         ******ERROR******                         |"
		echo "|                  FAILED TO OPEN PORT $httpPort/$httpsPort!                   |"
		echo "|          ERROR NO 'ufw' OR 'firewall-cmd' COMMAND FOUND!          |"
		echo "+-------------------------------------------------------------------+"
	fi

	
	read -p "Would you like to remove the cloned git directory $DIRECTORY? [Y/n] : " deleteOrNot
	if [[ $deleteOrNot == [nN] ]] || [[ $deleteOrNot == [nN][oO] ]]; then
		echo "Okay, keeping $DIRECTORY"
	else
		echo "Removing cloned git directory:$DIRECTORY..."
		rm -rf $DIRECTORY
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
	echo "Preparing to install needed dependancies for Jellyfin..."

	if [ -f /etc/os-release ]; then
		source /etc/os-release
		crbOrPowertools=
		os_detected=true
		echo "ID=$ID"
		
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
				fedora)	  dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
								dnf install $packagesNeededRHEL -y ;;
				rhel)		 dnf install epel-release -y
								dnf config-manager --set-enabled $crbOrPowertools
								dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm -y https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm -y
								dnf install $packagesNeededRHEL -y ;;
				debian)	  apt install $packagesNeededDebian -y ;;
				ubuntu)	  apt install $packagesNeededDebian -y ;;
				linuxmint)  apt install $packagesNeededDebian -y ;;
				elementary) apt install $packagesNeededDebian -y ;;
				arch)		 pacman -Syu $packagesNeededArch  ;;
				endeavouros) pacman -Syu $packagesNeededArch  ;;
				manjaro)	 pacman -Syu $packagesNeededArch  ;;
				opensuse*)  zypper install $packagesNeededOpenSuse ;;
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
		echo "Saving your current metadata to --> $tarPath"
	else
		tarPath=$backupDirectory/$fileName
		echo "Saving your current metadata to --> $tarPath"
	fi
	
	cd $currentJellyfinDirectory
	time tar cvf $tarPath data config
	USER=$(stat -c '%U' $backupDirectory)
	chown -f $USER:$USER $tarPath
	chmod -f 660 $tarPath
}


Previous_install()
{
	echo "WARNING: THIS OPTION IS HIGHLY UNSTABLE, ONLY USE IF YOU KNOW WHAT YOU'RE DOING!!!"
	echo
	read -p "Is Jellyfin CURRENTLY installed on this system? [y/N] : " currentlyInstalled

	if [[ $currentlyInstalled == [yY] ]] || [[ $currentlyInstalled == [yY][eE][sS] ]]; then
		isDataThere=false
		isConfigThere=false
		newDirectory=false
		
		while [ ! -d $currentJellyfinDirectory ]; do
			read -p "Where is Jellyfins intalled directory? : " currentJellyfinDirectory
			
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
				echo "Found metadata!"
			fi

			if [ ! -d "$currentJellyfinDirectory/config" ]; then
				echo "$currentJellyfinDirectory/config does not exist"
				isConfigThere=false
			else
				isConfigThere=true
				echo "Found config!"
			fi

			
			if ! $isDataThere || ! $isConfigThere; then
				echo "***ERROR*** - one or more directories not found..."
				echo "Would you like to try a different directory?"
				read -p ">>> [Y/n] : " newDirectory
				
				if [[ $newDirectory == [nN] ]]; then
					exit
				else
					currentJellyfinDirectory=null
				fi
			fi
			
		done
	
	Backup $HOME
	cd /opt/jellyfin
	tar xvf $tarPath -C ./
	
	fi
}

Setup()
{
	echo "Fetching newest stable Jellyfin version..."
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
	echo "Please enter the default user for Jellyfin"
	read -p ">>> " defaultUser
	while id "$defaultUser" &>/dev/null; do
		echo "Cannot create $defaultUser as $defaultUser already exists..."
		echo "Please re-enter a new default user for Jellyfin"
		read -p ">>> " defaultUser
	done
	
	defaultUser=${defaultUser,,}
	echo "Linux user = $defaultUser"
	useradd -rd /opt/jellyfin $defaultUser

	if [ -x "$(command -v apt)" ] || [ -x "$(command -v pacman)" ]; then
		cp $DIRECTORY/jellyman.1 /usr/share/man/man1/
	elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v zypper)" ]; then 
		cp $DIRECTORY/jellyman.1 /usr/local/share/man/man1/
	fi

	cp $DIRECTORY/scripts/jellyman /usr/bin/
	cp $DIRECTORY/scripts/jellyfin.sh /opt/jellyfin/
	touch /opt/jellyfin/config/jellyman.conf
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
	
	sed -ie "s|User.*|User=$defaultUser|g" $jellyfinServiceLocation/jellyfin.service
	cp $DIRECTORY/conf/jellyfin.conf /etc/
	jellyfinDir=/opt/jellyfin
	jellyfinConfigFile=$jellyfinDir/config/jellyman.conf
	tar xvzf $DIRECTORY/$jellyfin_archive
	mv -f $DIRECTORY/jellyfin /opt/jellyfin/$jellyfin
	ln -s $jellyfinDir/$jellyfin $jellyfinDir/jellyfin
	echo "architecture=$architecture" >> $jellyfinConfigFile
	echo "defaultPath=" >> $jellyfinConfigFile
	echo "apiKey=" >> $jellyfinConfigFile
	echo "httpPort=8096" >> $jellyfinConfigFile
	echo "httpsPort=8920" >> $jellyfinConfigFile
	echo "currentVersion=$jellyfin" >> $jellyfinConfigFile
	echo "defaultUser=$defaultUser" >> $jellyfinConfigFile
	echo "jellyfinServiceLocation=$jellyfinServiceLocation" >> $jellyfinConfigFile

	Install_dependancies

	echo "Setting Permissions for Jellyfin..."
	chown -R $defaultUser:$defaultUser /opt/jellyfin
	chmod u+x $jellyfinDir/jellyfin.sh
	chmod +rx /usr/bin/jellyman

	echo "Unblocking port 8096 and 8920..."
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

	echo
	echo
	echo "DONE"
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
	if $os_detected; then
		read -p "Press ENTER to continue" ENTER
		jellyman -h -e -s
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
	read -p " Press ENTER to continue" ENTER
	echo "Press 'q' to exit next screen"
	read -p " Press ENTER to continue" ENTER
	jellyman -t
	echo
	echo "Would you like to remove the cloned git directory $DIRECTORY?"
	read -p ">>> [Y/n] : " deleteOrNot
	if [[ $deleteOrNot == [nN] ]] || [[ $deleteOrNot == [nN][oO] ]]; then
		echo "Okay, keeping $DIRECTORY"
	else
		echo "Removing cloned git directory:$DIRECTORY..."
		rm -rf $DIRECTORY
	fi
}

Update_jellyman()
{
	sourceFile=/opt/jellyfin/config/jellyman.conf
	source $sourceFile
	echo "Updating Jellyman - The Jellyfin Manager"
	cp -f $DIRECTORY/scripts/jellyman /usr/bin/jellyman
	cp -f $DIRECTORY/scripts/jellyfin.sh /opt/jellyfin/jellyfin.sh
	chmod +rx /usr/bin/jellyman
	cp $DIRECTORY/conf/jellyfin.service /usr/lib/systemd/system/
	cp $DIRECTORY/conf/jellyfin-backup* /usr/lib/systemd/system/
	sed -ie "s|User.*|User=$defaultUser|g" $jellyfinServiceLocation/jellyfin.service
	
	if [ -x "$(command -v apt)" ] || [ -x "$(command -v pacman)" ]; then
		cp $DIRECTORY/jellyman.1 /usr/share/man/man1/
	elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v zypper)" ]; then 
		cp $DIRECTORY/jellyman.1 /usr/local/share/man/man1/
	fi
	
	if ( ! grep -q apiKey= "/opt/jellyfin/config/jellyman.conf" ); then
		echo "apiKey=" >> /opt/jellyfin/config/jellyman.conf
	fi

	if ( ! grep -q networkPort= "/opt/jellyfin/config/jellyman.conf" ) && ( ! grep -q httpPort= "/opt/jellyfin/config/jellyman.conf" ); then
		echo "networkPort=8096" >> /opt/jellyfin/config/jellyman.conf
	elif ( ! grep -q httpPort= "/opt/jellyfin/config/jellyman.conf" ) || ( ! grep -q httpsPort= "/opt/jellyfin/config/jellyman.conf" ); then
		sed -i -e "s|networkPort=.*|httpPort=8096|g" /opt/jellyfin/config/jellyman.conf
		echo "httpsPort=8920" >> /opt/jellyfin/config/jellyman.conf
	fi
	
	if [ -d /usr/lib/systemd ] && [[ ! -n $jellyfinServiceLocation ]]; then
		jellyfinServiceLocation="/usr/lib/systemd/system"
		echo "jellyfinServiceLocation=$jellyfinServiceLocation" >> $sourceFile
	elif [[ ! -n $jellyfinServiceLocation ]]; then
		jellyfinServiceLocation="/etc/systemd/system"
		echo "jellyfinServiceLocation=$jellyfinServiceLocation" >> $sourceFile
	fi

	if [ -d /usr/lib/systemd ]; then
		jellyfinServiceLocation="/usr/lib/systemd/system"
		sed -ie "s|jellyfinServiceLocation=.*|jellyfinServiceLocation=$jellyfinServiceLocation|g" /opt/jellyfin/config/jellyman.conf
	elif [[ ! -n $jellyfinServiceLocation ]]; then
		jellyfinServiceLocation="/etc/systemd/system"
		sed -ie "s|jellyfinServiceLocation=.*|jellyfinServiceLocation=$jellyfinServiceLocation|g" /opt/jellyfin/config/jellyman.conf
	fi

	if [[ ! -n $architecture ]]; then
		architecture=
		Get_Architecture
		echo "architecture=$architecture" >> /opt/jellyfin/config/jellyman.conf
	fi


	echo "Would you like to remove the cloned git directory $DIRECTORY?"
	read -p ">>> [Y/n] : " deleteOrNot
	if [[ $deleteOrNot == [nN] ]] || [[ $deleteOrNot == [nN][oO] ]]; then
		echo "Okay, keeping $DIRECTORY"
	else
		echo "Removing cloned git directory:$DIRECTORY..."
		rm -rf $DIRECTORY
	fi

	echo "...complete"
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
		echo "Please select the number corresponding with the option you want to select."
		read -p ">>> " optionNumber
		echo
		if [ $optionNumber -gt 3 ] || [ $optionNumber -lt 1 ]; then
			optionNumber=
			clear
			echo "ERROR: Please input an available option!"
			echo
		fi
	done


	case "$optionNumber" in
		1)	Setup  ;;
		2)	Update_jellyman ;;
		3)	Import;;
	esac
fi
