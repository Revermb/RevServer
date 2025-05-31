#!/bin/bash

# Prompt for username and password
read -p "Enter username: " username_user
read -s -p "Enter password: " password_user
echo  # Add a newline after the password prompt

# Update and install packages
apt update && apt upgrade -y
apt install xrdp qbittorrent docker -y

# Add users
adduser "$username_user" --quiet
adduser minecraft --quiet
adduser qbittorrent --quiet --system --group

# Set password for the user
echo "$username_user:$password_user" | chpasswd

# Add user to sudo group
usermod -aG sudo "$username_user"

# Install Java (globally)
wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb
dpkg -i jdk-21_linux-x64_bin.deb
apt-get install -f -y
update-alternatives --install "/usr/bin/java" "java" "/usr/java/jdk-21.0.3/bin/java" 1
update-alternatives --install "/usr/bin/javac" "javac" "/usr/java/jdk-21.0.3/bin/javac" 1

# Create systemd service file for qBittorrent
cat <<EOF > /etc/systemd/system/qbittorrent.service
[Unit]
Description=qBittorrent Daemon
After=network.target

[Service]
User=qbittorrent
ExecStart=/usr/bin/qbittorrent-nox -d --webui-port=8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable qbittorrent.service
systemctl start qbittorrent.service

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

systemctl daemon-reload
systemctl enable minecraft.service
systemctl start minecraft.service

# Make sure the minecraft user owns the directory
chown -R minecraft:minecraft /home/minecraft
