#!/bin/bash

#To run this file as safe as possible, please do
#```su -```
#before running it via
#```bash ./Userinstall.sh```

#///////////////////////////////////////////////////////////////////////
#///////////////////////DEFAULT USERS///////////////////////////////////
#///////////////////////////////////////////////////////////////////////

# Update and install packages
apt update && apt upgrade -y
apt install xrdp qbittorrent-nox wget -y

#Add users
adduser minecraft --quiet --system --group
adduser qbituser --quiet --system --group

#//////////////////////////////////////////////////////////////////////
#///////////////////////MINECRAFT//////////////////////////////////////
#//////////////////////////////////////////////////////////////////////
# Install Java (globally)
wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb
dpkg -i jdk-21_linux-x64_bin.deb
apt-get install -f -y

# Create the directories if they don't exist
mkdir -p /home/minecraft

# Download the Minecraft server JAR
wget -O /home/minecraft/server.jar https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar

# Make sure the minecraft user owns the directory & Jar
echo \n/////////////////////\n permissions for minecraft setup
chown -R minecraft:minecraft /home/minecraft
chmod 766 /home/minecraft/server.jar

#Setup Minecraft server
echo \n/////////////////////\n setting up minecraft
ufw enable
ufw allow 25565/tcp
cd /home/minecraft
java -jar /home/minecraft/server.jar --nogui

# Create systemd service file for Minecraft
echo \n/////////////////////\nCreating Systemd services
cat <<EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=minecraft
WorkingDirectory=/home/minecraft
ExecStart=/usr/lib/jvm/jdk-21.0.7-oracle-x64/bin/java -Xms2G -Xmx4G -jar /home/minecraft/server.jar --nogui
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
#////////////////////////////////////////////////////////////
#/////////////////QBITTORRENT////////////////////////////////
#////////////////////////////////////////////////////////////
#Setup Qbittorrent user enviroment
echo \n/////////////////////\n setting up qbittorrent
mkdir -p /home/qbituser
mkdir -p /home/qbituser/rv-nas
cd /home/qbituser

# Set ownership and permissions
chown -R qbituser:qbituser /home/qbituser
chmod 750 /home/qbituser
chmod 750 /home/qbituser/rv-nas

#Starting qbittorrent
echo y | qbittorrent-nox

#//////////////////////////////////////////////////////////////
#/////////////////////SYSTEMD ENABLES//////////////////////////
#//////////////////////////////////////////////////////////////
# Reload systemd, enable and start services
systemctl daemon-reload
systemctl enable qbittorrent-nox@qbituser
systemctl enable minecraft.service
systemctl start qbittorrent-nox@qbituser
systemctl start minecraft.service