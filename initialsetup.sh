#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo."
    exit 1
fi

echo "Installing required packages..."

sudo apt-get install net-tools -y
sudo apt-get install hfsprogs -y

echo "Creating datapool group..."
sudo groupadd datapool

sudo mkdir /mnt/blackbear
sudo mkdir /mnt/cupcake
sudo mkdir /mnt/icecream
sudo mkdir /mnt/milkshake

sudo chgrp datapool /mnt/blackbear
sudo chgrp datapool /mnt/cupcake
sudo chgrp datapool /mnt/icecream
sudo chgrp datapool /mnt/milkshake

sudo chmod u+rwx,g+srwx,o-rwx /mnt/cupcake

sudo usermod -aG datapool $USER

echo "Configuring mounting drives..."
cat ./fstab >> /etc/fstab

ip_address=$(hostname -I | awk '{print $1}')

echo "Installing qBittorrent..."

sudo apt install qbittorrent-nox -y
sudo useradd -r -m qbittorrent
sudo usermod -aG datapool qbittorrent

cp ./qbittorrent.service /etc/systemd/system/qbittorrent.service
sudo systemctl enable qbittorrent
sudo systemctl start qbittorrent

echo "Qbittorrent is running at http://$ip_address:8080"

echo "Installing Samba and avahi..."
sudo apt-get install samba samba-common-bin avahi-daemon -y
cp ./smb.conf /etc/samba/smb.conf
sudo smbpasswd -a akshobg

cp ./samba.service /etc/avahi/services/samba.service

sudo systemctl enable smbd avahi-daemon

echo "Installing Plex Media Server..."

curl https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /usr/share/keyrings/plex-archive-keyring.gpg >/dev/null
echo deb [signed-by=/usr/share/keyrings/plex-archive-keyring.gpg] https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
sudo apt-get update
sudo apt install plexmediaserver

sudo usermod -aG datapool plex

echo "Configure Plex Media Server at http://$ip_address:32400/web"
