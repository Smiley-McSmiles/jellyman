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
		echo "Please use 'sudo ./setup.sh' to install the scripts."
		exit
	fi
}

Import()
{
	Has_sudo
	importTar=$1
	echo "|-------------------------------------------------------------------|"
	echo "|                        ******WARNING******                        |"
	echo "|                        ******CAUTION******                        |"
	echo "|This procedure should only be used as a fresh install of Jellyfin. |"
	echo "|       As this procedure will erase /opt/jellyfin COMPLETELY       |"
	echo "|-------------------------------------------------------------------|"

	read -p "...Continue? [yes/No] :" importOrNotToImport
	if [[ $importOrNotToImport == [yY][eE][sS] ]]; then
		echo "IMPORTING $importTar"
		jellyman -S
		rm -rf /opt/jellyfin
		tar xvf $importTar -C /
		clear
		source /opt/jellyfin/config/jellyman.conf
		mv -f /opt/jellyfin/backup/jellyman /bin/
		chmod +x /bin/jellyman
		
		if [ -d /usr/lib/systemd/system ]; then
			mv -f /opt/jellyfin/backup/jellyfin.service /usr/lib/systemd/system/
		else
			mv -f /opt/jellyfin/backup/jellyfin.service /etc/systemd/system
		fi
		
		mv -f /opt/jellyfin/backup/jellyfin.conf /etc/
		if id "$defaultUser" &>/dev/null; then 
			chown -Rfv $defaultUser:$defaultUser /opt/jellyfin
			chmod -Rfv 770 /opt/jellyfin
			Install_dependancies
			jellyman -e -s -t
		else
			clear
			echo "|-----------------------------------------------------------------------------------------------|"
			echo "|                                     ******WARNING******                                       |"
			echo "|                                     *******ERROR*******                                       |"
			echo "|          The imported default Jellyfin user($defaultUser) has not yet been created.           |"
			echo "|    This error is likely due to a read error of the /opt/jellyfin/config/jellyman.conf file.   |"
			echo "| The default user is usually created by Jellyman - The Jellyfin Manager, when running setup.sh.|"
			echo "|                   You may want to see who owns that configuration file with:                  |"
			echo "|                          'ls -l /opt/jellyfin/config/jellyman.conf'                           |"
			echo "|-----------------------------------------------------------------------------------------------|"
			sleep 5
			read -p "...Continue with $defaultUser? [yes/No] :" newUserOrOld
			if [[ $newUserOrOld == [yY][eE][sS] ]]; then
				echo "Great!"
				sleep .5
				chown -Rfv $defaultUser:$defaultUser /opt/jellyfin
				chmod -Rfv 770 /opt/jellyfin
				Install_dependancies
				jellyman -s -t
			else
				read -p "No? Which user should own /opt/jellyfin?: " defaultUser
				echo "Well... I should've known $defaultUser would be the one..."
				sleep 1
				read -p "Please enter the default user for Jellyfin: " defaultUser
		while id "$defaultUser" &>/dev/null; do
			  echo "Cannot create $defaultUser as $defaultUser already exists..."
			  read -p "Please re-enter a new default user for Jellyfin: " defaultUser
		 done
		 
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
	packagesNeededDebian='ffmpeg git net-tools openssl bc screen'
	packagesNeededRHEL='ffmpeg ffmpeg-devel ffmpeg-libs git openssl bc screen'
	packagesNeededArch='ffmpeg git openssl bc screen'
	packagesNeededOpenSuse='ffmpeg-4 git openssl bc screen'
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
		echo "|-------------------------------------------------------------------|"
		echo "|                       ******WARNING******                         |"
		echo "|                        ******ERROR******                          |"
		echo "|               FAILED TO FIND /etc/os-release FILE.                |"
		echo "|              PLEASE MANUALLY INSTALL THESE PACKAGES:              |"
		echo "|                     ffmpeg git AND openssl                        |"
		echo "|-------------------------------------------------------------------|"
		
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
	read -p "Is there a current install of Jellyfin on this system? [y/N] : " currentlyInstalled

	if [[ $currentlyInstalled == [yY]* ]]; then
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
				read -p "Would you like to try a different directory? [Y/n] : " newDirectory
				
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
	Has_sudo
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

	read -p "Please enter the default user for Jellyfin: " defaultUser
	while id "$defaultUser" &>/dev/null; do
		echo "Cannot create $defaultUser as $defaultUser already exists..."
		read -p "Please re-enter a new default user for Jellyfin: " defaultUser
	done

	useradd -rd /opt/jellyfin $defaultUser

	if [ -x "$(command -v apt)" ] || [ -x "$(command -v pacman)" ]; then
		cp $DIRECTORY/jellyman.1 /usr/share/man/man1/
	elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v zypper)" ]; then 
		cp $DIRECTORY/jellyman.1 /usr/local/share/man/man1/
	fi

	cp $DIRECTORY/scripts/jellyman /bin/
	cp $DIRECTORY/scripts/jellyfin.sh /opt/jellyfin/
	touch /opt/jellyfin/config/jellyman.conf
	jellyfinServiceLocation=
	
	if [ -d /usr/lib/systemd/system ]; then
		cp $DIRECTORY/conf/jellyfin.service /usr/lib/systemd/system/
		jellyfinServiceLocation="/usr/lib/systemd/system/jellyfin.service"
	else
		cp $DIRECTORY/conf/jellyfin.service /etc/systemd/system/
		jellyfinServiceLocation="/etc/systemd/system/jellyfin.service"
	fi
	
	sed -i -e "s|User=jellyfin|User=$defaultUser|g" $jellyfinServiceLocation
	cp $DIRECTORY/conf/jellyfin.conf /etc/
	cd /opt/jellyfin
	tar xvzf $DIRECTORY/$jellyfin_archive
	mv -f /opt/jellyfin/jellyfin /opt/jellyfin/$jellyfin
	ln -s $jellyfin jellyfin
	echo "architecture=$architecture" >> config/jellyman.conf
	echo "defaultPath=" >> config/jellyman.conf
	echo "apiKey=" >> config/jellyman.conf
	echo "httpPort=8096" >> config/jellyman.conf
	echo "httpsPort=8920" >> config/jellyman.conf
	echo "currentVersion=$jellyfin" >> config/jellyman.conf
	echo "defaultUser=$defaultUser" >> config/jellyman.conf
	echo "jellyfinServiceLocation=$jellyfinServiceLocation" >> config/jellyman.conf

	Install_dependancies

	echo "Setting Permissions for Jellyfin..."
	chown -R $defaultUser:$defaultUser /opt/jellyfin
	chmod u+x jellyfin.sh
	chmod +x /bin/jellyman

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
		echo "|-------------------------------------------------------------------|"
		echo "|                        ******WARNING******                        |"
		echo "|                         ******ERROR******                         |"
		echo "|                  FAILED TO OPEN PORT 8096/8920!                   |"
		echo "|          ERROR NO 'ufw' OR 'firewall-cmd' COMMAND FOUND!          |"
		echo "|-------------------------------------------------------------------|"
	fi

	echo
	echo
	echo "DONE"
	echo
	echo "|-------------------------------------------------------------------|"
	echo "|                 Navigate to http://localhost:8096/                |"
	echo "|         in your Web Browser to claim your Jellyfin server         |"
	echo "|-------------------------------------------------------------------|"
	echo
	echo "|-------------------------------------------------------------------|"
	echo "|         To enable https please enter 'sudo jellyman -rc'          |"
	echo "|       (After you have navigated to the Jellyfin Dashboard)        |"
	echo "|                                                                   |"
	echo "|                To manage Jellyfin use 'jellyman -h'               |"
	echo "|-------------------------------------------------------------------|"
	echo
	if $os_detected; then
		read -p "Press ENTER to continue" ENTER
		jellyman -h -e -s
	else
		jellyman -h 
		echo "|-------------------------------------------------------------------|"
		echo "|                        ******WARNING******                        |"
		echo "|            JELLYFIN MEDIA SERVER NOT ENABLED OR STARTED           |"
		echo "|               FAILED TO FIND /etc/os-release FILE.                |"
		echo "|             PLEASE MANUALLY INSTALL THESE PACKAGES:               |"
		echo "|                     ffmpeg git AND openssl                        |"
		echo "|       THEN RUN: jellyman -e -s TO ENABLE AND START JELLYFIN       |"
		echo "|-------------------------------------------------------------------|"
	fi
	echo
	read -p " Press ENTER to continue" ENTER
	echo "Press 'q' to exit next screen"
	read -p " Press ENTER to continue" ENTER
	jellyman -t
	echo
	read -p "Would you like to remove the cloned git directory $DIRECTORY? [Y/n] : " deleteOrNot
	if [[ $deleteOrNot == [nN]* ]]; then
		echo "Okay, keeping $DIRECTORY"
	else
		echo "Removing cloned git directory:$DIRECTORY..."
		rm -rf $DIRECTORY
	fi
}

Pre_setup()
{
	echo "|-------------------------------------------------------------------|"
	echo "|                    No commands recognized                         |"
	echo "|                     setup.sh options are:                         |"
	echo "|                                                                   |"
	echo "|  -i [jellyfin-backup.tar] Import .tar to pick up where you left   |"
	echo "|                    off on another machine                         |"
	echo "|                                                                   |"
	echo "|                    -U Update Jellyman only.                       |"
	echo "|-------------------------------------------------------------------|"
	echo
	echo "Press ENTER to continue with first time setup or CTRL+C to exit..."
	read ENTER
}

Update_jellyman()
{
	Has_sudo
	source /opt/jellyfin/config/jellyman.conf
	echo "Updating Jellyman - The Jellyfin Manager"
	cp -f scripts/jellyman /bin/jellyman
	cp -f scripts/jellyfin.sh /opt/jellyfin/jellyfin.sh
	chmod +x /bin/jellyman
	if [ -x "$(command -v apt)" ] || [ -x "$(command -v pacman)" ]; then
		cp jellyman.1 /usr/share/man/man1/
	elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v zypper)" ]; then 
		cp jellyman.1 /usr/local/share/man/man1/
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
		bash -c 'echo "jellyfinServiceLocation=/usr/lib/systemd/system/jellyfin.service" >> /opt/jellyfin/config/jellyman.conf'
	elif [[ ! -n $jellyfinServiceLocation ]]; then
		bash -c 'echo "jellyfinServiceLocation=/etc/systemd/system/jellyfin.service" >> /opt/jellyfin/config/jellyman.conf'
	fi

	if [[ ! -n $architecture ]]; then
		architecture=
		Get_Architecture
		echo "architecture=$architecture" >> /opt/jellyfin/config/jellyman.conf
	fi

	echo "...complete"
}


if [ -n "$1" ]; then
	while [ -n "$1" ]; do
		case "$1" in
			-i)	Import $2
					rm -rf $DIRECTORY
					exit ;;
			-U)	Update_jellyman
					rm -rf $DIRECTORY
					exit ;;
			*)	 Pre_setup 
					setup  ;;
		esac
		shift
	done
else
	Pre_setup
	Setup
	exit
fi


