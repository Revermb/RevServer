#!/bin/bash

#To run this file as safe as possible, please do
#```su -```
#before running it via
#```bash ./Userinstall.sh```


# Update and install packages
apt update && apt upgrade -y
apt install xrdp qbittorrent docker wget -y

#Add users
adduser minecraft --quiet --system --group
echo "Create password for minecraft user"
passwd minecraft
adduser qbittorrent --quiet --system --group
echo "Create password for qbittorrent user"
passwd qbittorrent

# Install Java (globally)
wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb
dpkg -i jdk-21_linux-x64_bin.deb
apt-get install -f -y

# Create the directories if they don't exist
mkdir -p /home/minecraft
mkdir -p /home/qbittorrent

# Download the Minecraft server JAR
wget -O /home/minecraft/server.jar https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar

# Make sure the minecraft user owns the directory & Jar
chown -R minecraft:minecraft /home/minecraft
chmod 766 /home/minecraft/server.jar

#Setup Minecraft server
cd /home/minecraft
java -jar /home/minecraft/server.jar --nogui

#Setup Qbittorrent-nox server
cd /home/qbittorrent
su qbittorrent
qbittorrent
# Create systemd service file for qBittorrent
cat <<EOF > /etc/systemd/system/qbittorrent.service
[Unit]
Description=qBittorrent Daemon
After=network.target

[Service]
User=qbittorrent
ExecStart=/usr/bin/qbittorrent -d --webui-port=8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service file for Minecraft
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
systemctl enable qbittorrent.service
systemctl enable minecraft.service
systemctl start qbittorrent.service
systemctl start minecraft.service