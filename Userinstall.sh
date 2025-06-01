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
cd /home/minecraft
java -jar /home/minecraft/server.jar --nogui

#Setup Qbittorrent-nox server
echo \n/////////////////////\n setting up qbittorrent
cd /home/qbituser

# Create qBittorrent service configuration directory
mkdir -p /home/qbituser/.config/qBittorrent
chown -R qbituser:qbituser /home/qbituser/.config/qBittorrent

# Set proper permissions for qBittorrent home
chmod 750 /home/qbituser

# Create default qBittorrent config (optional but recommended)
cat <<EOF > /home/qbituser/.config/qBittorrent/qBittorrent.conf
[LegalNotice]
Accepted=true

[Preferences]
WebUI\Username=admin
WebUI\Port=8080
WebUI\CSRFProtection=true
WebUI\ClickjackingProtection=true
WebUI\SecureCookie=true
EOF

chown qbituser:qbituser /home/qbituser/.config/qBittorrent/qBittorrent.conf
chmod 600 /home/qbituser/.config/qBittorrent/qBittorrent.conf

# Create systemd service file for Minecraft
echo \n/////////////////////\nCreating Systemd services
cat <<EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=minecraft
WorkingDirectory=/home/minecraft  # Or wherever your server files are
ExecStart=/usr/bin/java -Xms1G -Xmx4G -jar /home/minecraft/server.jar nogui
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start services
systemctl daemon-reload
systemctl enable qbittorrent-nox@qbituser
systemctl enable minecraft.service
systemctl start qbittorrent-nox@qbituser
systemctl start minecraft.service