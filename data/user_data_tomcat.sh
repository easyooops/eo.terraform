Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
# Update SSH configuration to listen on port 70
sudo sed -i 's/^#Port 22/Port 70/' /etc/ssh/sshd_config
sudo service ssh restart

# Update packages
apt-get update

# Install Java
apt-get install -y default-jdk

# Download Apache Tomcat
wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.54/bin/apache-tomcat-9.0.54.tar.gz

# Extract Tomcat archive
tar xvzf apache-tomcat-9.0.54.tar.gz

# Move Tomcat directory to /opt
mv apache-tomcat-9.0.54 /opt/tomcat

# Set permissions
chown -R ubuntu:ubuntu /opt/tomcat
chmod +x /opt/tomcat/bin/*.sh

# Create a systemd service for Tomcat
cat << EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat
After=network.target

[Service]
Type=forking
User=ubuntu
Group=ubuntu
Environment=JAVA_HOME=/usr/lib/jvm/default-java
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Start Tomcat service
systemctl start tomcat

# Enable Tomcat service to start on system boot
systemctl enable tomcat

--//--