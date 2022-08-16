#!/bin/bash
DIRECTORY=$(cd `dirname $0` && pwd)
has_sudo_access=""
`timeout -k .1 .1 bash -c "sudo /bin/chmod --help" >&/dev/null 2>&1` >/dev/null 2>&1
if [ $? -eq 0 ];then
   has_sudo_access="YES"
	echo "Hey $USER! My old friend..."
	sleep 2
else
   has_sudo_access="NO"
	echo "$USER, you're not using sudo..."
	echo "Please use 'sudo ./setup.sh' to install the scripts."
	exit
fi

Import()
{
   Has_sudo
   importTar=$1
   echo "******WARNING******"
   echo "******CAUTION******"
   echo "This procedure should only be used as a fresh install of Jellyfin."
   echo "As this procedure will erase /opt/jellyfin COMPLETELY"
   sleep 5
   read -p "...Continue? [yes/No] :" importOrNotToImport
   if [[ $importOrNotToImport == [yY][eE][sS] ]]; then
      echo "IMPORTING $importTar"
      jellyman -S
      rm -rf /opt/jellyfin
      tar xvf $importTar -C /
      clear
      source /opt/jellyfin/config/jellyman.conf
      mv -f /opt/jellyfin/backup/jellyfin /bin/
      chmod +x /bin/jellyfin
      mv -f /opt/jellyfin/backup/jellyfin.service /usr/lib/systemd/system/
      mv -f /opt/jellyfin/backup/jellyman.conf /etc/
      if id "$defaultUser" &>/dev/null; then 
         chown -Rfv $defaultUser:$defaultUser /opt/jellyfin
         chmod -Rfv 770 /opt/jellyfin
         jellyman -s -t
      else
         clear
         echo "******WARNING******"
         echo "*******ERROR*******"
         echo "The imported default Jellyfin user($defaultUser) has not yet been created."
         echo "This error is likely due to a read error of the /opt/jellyfin/config/jellyman.conf file."
         echo "The default user is usually created by Jellyman - The Jellyfin Manager, when running setup.sh."
         echo "You may want to see who owns that configuration file with:"
         echo "'ls -l /opt/jellyfin/config/jellyman.conf'"
         sleep 5
         read -p "...Continue with $defaultUser? [yes/No] :" newUserOrOld
         if [[ $newUserOrOld == [yY][eE][sS] ]]; then
            echo "Great!"
            sleep .5
            chown -Rfv $defaultUser:$defaultUser /opt/jellyfin
            chmod -Rfv 770 /opt/jellyfin
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
            jellyman -s -t
         fi
      fi

   else
      echo "Returning..."
   fi    
}

if [ -n "$1" ]; then
   Import $2
   rm -rf $DIRECTORY
   exit
fi

echo "Fetching newest stable Jellyfin version..."
wget https://repo.jellyfin.org/releases/server/linux/stable/combined/
jellyfin_archive=$(grep 'amd64.tar.gz"' index.html | cut -d '"' -f 2)
rm index.html
wget https://repo.jellyfin.org/releases/server/linux/stable/combined/$jellyfin_archive
jellyfin=$(echo $jellyfin_archive | sed -r 's/_amd64.tar.gz//g')

mkdir /opt/jellyfin
clear

read -p "Please enter the default user for Jellyfin: " defaultUser
while id "$defaultUser" &>/dev/null; do
   echo "Cannot create $defaultUser as $defaultUser already exists..."
   read -p "Please re-enter a new default user for Jellyfin: " defaultUser
done

useradd -rd /opt/jellyfin $defaultUser

mkdir /opt/jellyfin/old /opt/jellyfin/backup

if [ -x "$(command -v apt)" ]; then
cp jellyman.1 /usr/share/man/man1/
elif [ -x "$(command -v dnf)" ]; then 
cp jellyman.1 /usr/local/share/man/man1/
elif [ -x "$(command -v pacman)" ]; then 
cp jellyman.1 /usr/share/man/man1/
elif [ -x "$(command -v zypper)" ]; then 
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
mkdir data cache config log
touch config/jellyman.conf
echo "defaultPath=" >> config/jellyman.conf
echo "apiKey=" >> config/jellyman.conf
echo "httpPort=8096" >> config/jellyman.conf
echo "httpsPort=8920" >> config/jellyman.conf
echo "currentVersion=$jellyfin" >> config/jellyman.conf
echo "defaultUser=$defaultUser" >> config/jellyman.conf

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
	echo "FAILED TO INSTALL PACKAGES: Package manager not found. You must manually install: ffmpeg and git";
fi

echo "creating OpenSSL self signed certificate for https. Valid for the next 365 days."
mkdir /opt/jellyfin/cert
openssl req -x509 -newkey rsa:4096 -keyout /opt/jellyfin/cert/privkey.pem -out /opt/jellyfin/cert/cert.pem -days 365 -nodes -subj '/CN=jellyfin.lan'
openssl pkcs12 -export -out /opt/jellyfin/cert/jellyfin.pfx -inkey /opt/jellyfin/cert/privkey.pem -in /opt/jellyfin/cert/cert.pem -passout pass:


echo "Setting Permissions for Jellyfin..."
chown -R $defaultUser:$defaultUser /opt/jellyfin
chmod u+x jellyfin.sh
chmod +x /bin/jellyman

echo "Unblocking port 8096 and 8920..."
if [ -x "$(command -v ufw)" ]; then
	ufw allow 8096
	ufw allow 8920
	ufw reload
elif [ -x "$(command -v firewall-cmd)" ]; then 
	firewall-cmd --permanent --zone=public --add-port=8096/tcp
	firewall-cmd --permanent --zone=public --add-port=8920/tcp
	firewall-cmd --reload
else echo "FAILED TO OPEN PORT 8096/8920! ERROR NO 'ufw' OR 'firewall-cmd' COMMAND FOUND!";
fi

echo "Enabling jellyfin.service..."
sed -i -e "s|User=jellyfin|User=$defaultUser|g" /usr/lib/systemd/system/jellyfin.service
systemctl enable --now jellyfin.service
echo

echo "Enabling https..."
sed -i -e "s|<EnableHttps>*</EnableHttps>|<EnableHttps>true</EnableHttps>|g" /opt/jellyfin/config/network.xml
sed -i -e "s|<CertificatePath>*</CertificatePath>|<CertificatePath>/opt/jellyfin/cert/jellyfin.pfx</CertificatePath>|g" /opt/jellyfin/config/network.xml

echo "Removing git cloned directory:$DIRECTORY..."
rm -rf $DIRECTORY
echo

echo
echo "DONE"
echo
echo "Navigate to http://localhost:8096/ or https://localhost:8920/"
echo "in your Web Browser to claim your Jellyfin server"
echo
echo "To manage Jellyfin use 'jellyman -h'"
echo
read -p "Press ENTER to continue" ENTER
jellyman -h
read -p "Press ENTER to continue" ENTER
systemctl status jellyfin.service
