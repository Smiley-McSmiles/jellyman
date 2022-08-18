#!/bin/bash
DIRECTORY=$(cd `dirname $0` && pwd)
has_sudo_access=
architecture=

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
      mv -f /opt/jellyfin/backup/jellyfin.service /usr/lib/systemd/system/
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
         echo "|             The imported default Jellyfin user($defaultUser) has not yet been created.        |"
         echo "|   This error is likely due to a read error of the /opt/jellyfin/config/jellyman.conf file.    |"
         echo "| The default user is usually created by Jellyman - The Jellyfin Manager, when running setup.sh.|"
         echo "|                 You may want to see who owns that configuration file with:                    |"
         echo "|                         'ls -l /opt/jellyfin/config/jellyman.conf'                            |"
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
   cpuArchitectureFull=$(lscpu | grep Architecture | rev | cut -d " " -f1 | rev)
   if [[ $cpuArchitectureFull == "x86_64" ]]; then
      architecture="amd64"
   elif [[ $cpuArchitectureFull == "aarch64" ]]; then
      architecture="arm64"
   else
      echo "ERROR UNKNOWN CPU ARCHITECTURE.. EXITING."
      exit
   fi
}

Install_dependancies()
{
   echo "Preparing to install needed dependancies for Jellyfin..."
   echo

   packagesNeededDebian='ffmpeg git net-tools openssl'
   packagesNeededFedora='ffmpeg ffmpeg-devel ffmpeg-libs git openssl'
   packagesNeededArch='ffmpeg git openssl'
   packagesNeededOpenSuse='ffmpeg-4 git openssl'
   if [ -x "$(command -v apt)" ]; then
      add-apt-repository universe -y
      apt update -y
      apt install $packagesNeededDebian -y
   elif [ -x "$(command -v dnf)" ]; then 
      dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
      dnf install $packagesNeededFedora -y
   elif [ -x "$(command -v pacman)" ]; then
       pacman -Syu $packagesNeededArch
   elif [ -x "$(command -v zypper)" ]; then
       zypper install $packagesNeededOpenSuse
   else 
      echo "|----------------------------------------------------------------------------------------------------|"
      echo "|                                       ******WARNING******                                          |"
      echo "|                                       *******ERROR*******                                          |"
      echo "|        FAILED TO INSTALL PACKAGES: Package manager not found. You must manually install:           |"
      echo "|                                    ffmpeg, git, and openssl                                        |"
      echo "|----------------------------------------------------------------------------------------------------|"
   fi

}

Setup()
{
   echo "Fetching newest stable Jellyfin version..."
   Get_Architecture
   wget https://repo.jellyfin.org/releases/server/linux/stable/combined/
   jellyfin_archive=$(grep "$architecture.tar.gz" index.html | cut -d '"' -f 2 | sed -r "s|.sha256sum||g" | head -1)
   rm index.html
   wget https://repo.jellyfin.org/releases/server/linux/stable/combined/$jellyfin_archive
   jellyfin=$(echo $jellyfin_archive | sed -r "s|_$architecture.tar.gz||g")

   mkdir /opt/jellyfin
   clear

   read -p "Please enter the default user for Jellyfin: " defaultUser
   while id "$defaultUser" &>/dev/null; do
      echo "Cannot create $defaultUser as $defaultUser already exists..."
      read -p "Please re-enter a new default user for Jellyfin: " defaultUser
   done

   useradd -rd /opt/jellyfin $defaultUser

   mkdir /opt/jellyfin/old /opt/jellyfin/backup

   if [ -x "$(command -v apt)" ] || [ -x "$(command -v pacman)" ]; then
      cp jellyman.1 /usr/share/man/man1/
   elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v zypper)" ]; then 
      cp jellyman.1 /usr/local/share/man/man1/
   fi

   cp scripts/jellyman /bin/
   cp scripts/jellyfin.sh /opt/jellyfin/
   mv $jellyfin_archive /opt/jellyfin/
   cp conf/jellyfin.service /usr/lib/systemd/system/
   cp conf/jellyfin.conf /etc/
   cd /opt/jellyfin
   tar xvzf $jellyfin_archive
   rm -f $jellyfin_archive
   ln -s $jellyfin jellyfin
   mkdir data cache config log cert
   touch config/jellyman.confecho "architecture=$architecture" >> config/jellyman.conf
   echo "defaultPath=" >> config/jellyman.conf
   echo "apiKey=" >> config/jellyman.conf
   echo "httpPort=8096" >> config/jellyman.conf
   echo "httpsPort=8920" >> config/jellyman.conf
   echo "currentVersion=$jellyfin" >> config/jellyman.conf
   echo "defaultUser=$defaultUser" >> config/jellyman.conf

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
      echo "|                        ******CAUTION******                        |"
      echo "|                  FAILED TO OPEN PORT 8096/8920!                   |"
      echo "|          ERROR NO 'ufw' OR 'firewall-cmd' COMMAND FOUND!          |"
      echo "|-------------------------------------------------------------------|"
   fi

   echo "Enabling jellyfin.service..."
   sed -i -e "s|User=jellyfin|User=$defaultUser|g" /usr/lib/systemd/system/jellyfin.service
   echo

   echo "Removing git cloned directory:$DIRECTORY..."
   rm -rf $DIRECTORY
   echo

   echo
   echo "DONE"
   echo
   echo "|-------------------------------------------------------------------|"
   echo "|   Navigate to http://localhost:8096/ or https://localhost:8920/   |"
   echo "|        in your Web Browser to claim your Jellyfin server          |"
   echo "|-------------------------------------------------------------------|"
   echo
   echo "|-------------------------------------------------------------------|"
   echo "|         To enable https please enter 'sudo jellyman -rc'          |"
   echo "|             To manage Jellyfin use 'jellyman -h'                  |"
   echo "|-------------------------------------------------------------------|"
   echo
   read -p " Press ENTER to continue" ENTER
   jellyman -h -e -s
   echo
   read -p " Press ENTER to continue" ENTER
   jellyman -t
}

Pre_setup()
{
   echo "|-------------------------------------------------------------------|"
   echo "|                     No commands recognized                        |"
   echo "|                      setup.sh options are:                        |"
   echo "|                                                                   |"
   echo "|  -i [jellyfin-backup.tar] Import .tar to pick up where you left   |" 
   echo "|                    off on another machine                         |"
   echo "|                                                                   |"
   echo "|                  -U Update Jellyman only.                         |"
   echo "|-------------------------------------------------------------------|"
   echo
   echo "Press ENTER to continue with first time setup or CTRL+C to exit..."
   read ENTER
}

Update-jellyman()
{
   Has_sudo
   echo "Updating Jellyman - The Jellyfin Manager"
   cp -f scripts/jellyman /usr/bin/
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
   echo "...complete"
}


if [ -n "$1" ]; then
   while [ -n "$1" ]; do
      case "$1" in
         -i)   Import $2
               rm -rf $DIRECTORY
               exit ;;
         -U)   Update_jelllyman
               rm -rf $DIRECTORY
               exit ;;
         *)    Pre_setup 
               setup  ;;
      esac
      shift
   done
else
   Pre_setup
   Setup
   exit
fi


