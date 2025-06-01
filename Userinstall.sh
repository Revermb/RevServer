#!/bin/bash

#To run this file as safe as possible, please do
#```su -```
#before running it via
#```bash ./Userinstall.sh```


# Update and install packages
apt update && apt upgrade -y
apt install xrdp qbittorrent-nox wget -y

#Add users
adduser minecraft --quiet --system --group
echo "Create password for minecraft user"
passwd minecraft
sudo usermod -s /usr/sbin/nologin minecraft
adduser qbituser --quiet --system --group
echo "Create password for qbittorrent user"
passwd qbituser
sudo usermod -s /usr/sbin/nologin qbituser

# Install Java (globally)
wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb
dpkg -i jdk-21_linux-x64_bin.deb
apt-get install -f -y

# Create the directories if they don't exist
mkdir -p /home/minecraft
mkdir -p /home/qbituser

# Download the Minecraft server JAR
wget -O /home/minecraft/server.jar https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar

# Make sure the minecraft user owns the directory & Jar
echo \n/////////////////////\n permissions for minecraft setup
chown -R minecraft:minecraft /home/minecraft
chmod 766 /home/minecraft/server.jar

#Setup Minecraft server
echo \n/////////////////////\n setting up minecraft
ufw enable
ufw allow 25565
cd /home/minecraft
java -jar /home/minecraft/server.jar --nogui

#Setup Qbittorrent-nox server
echo -e "\n/////////////////////\n setting up qbittorrent"
cd /home/qbituser

# Create necessary directories
mkdir -p /home/qbituser/.config/qBittorrent
mkdir -p /home/qbituser/downloads
mkdir -p /home/qbituser/downloads/temp
mkdir -p /home/qbituser/torrents

# Set ownership and permissions
chown -R qbituser:qbituser /home/qbituser
chmod 750 /home/qbituser
chmod 770 /home/qbituser/downloads
chmod 770 /home/qbituser/downloads/temp
chmod 750 /home/qbituser/torrents

# Create qBittorrent service file
cat <<EOF > /etc/systemd/system/qbittorrent-nox@.service
[Unit]
Description=qBittorrent-nox service
After=network.target

[Service]
Type=forking
User=%i
Group=%i
UMask=007
Environment="XDG_CONFIG_HOME=/home/%i/.config"
ExecStart=/usr/bin/qbittorrent-nox -d --webui-port=8080
ExecStop=/usr/bin/killall -w -s 9 /usr/bin/qbittorrent-nox
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Create enhanced qBittorrent config
cat <<EOF > /home/qbituser/.config/qBittorrent/qBittorrent.conf
[LegalNotice]
Accepted=true

[Preferences]
WebUI\Username=admin
WebUI\Port=8080
WebUI\CSRFProtection=true
WebUI\ClickjackingProtection=true
WebUI\SecureCookie=true
Downloads\SavePath=/home/qbituser/downloads
Downloads\TempPath=/home/qbituser/downloads/temp
Downloads\TempPathEnabled=true
Connection\PortRangeMin=6881
Connection\RandomPort=false
BitTorrent\MaxConnecs=500
BitTorrent\MaxConnecsPerTorrent=100
BitTorrent\MaxRatio=1
BitTorrent\MaxRatioAction=0
EOF

# Set proper permissions
chown -R qbituser:qbituser /home/qbituser/.config
chmod 600 /home/qbituser/.config/qBittorrent/qBittorrent.conf

# Create systemd service file for Minecraft
echo \n/////////////////////\nCreating Systemd services
cat <<EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=minecraft
WorkingDirectory=/home/minecraft
ExecStart=/usr/lib/jvm/jdk-21.0.7-oracle-x64/bin/java -Xms1G -Xmx4G -jar /home/minecraft/server.jar --nogui
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start services
systemctl daemon-reload
systemctl enable qbittorrent-nox@qbituser
systemctl enable minecraft.service
systemctl start qbittorrent-nox@qbituser
systemctl start minecraft.service