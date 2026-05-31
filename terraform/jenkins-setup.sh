#!/bin/bash
yum update -y

amazon-linux-extras install -y docker
service docker start
usermod -a -G docker ec2-user

curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

yum install -y git
yum install -y java-11-openjdk

cat <<EOF > /etc/systemd/system/jenkins.service
[Unit]
Description=Jenkins
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/usr/bin/java -jar /home/ec2-user/jenkins.war
WorkingDirectory=/home/ec2-user
Restart=always

[Install]
WantedBy=multi-user.target
EOF

curl -L -o /home/ec2-user/jenkins.war https://get.jenkins.io/war/latest/jenkins.war
curl -L -o /home/ec2-user/jdk-11.tar.gz https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.9.1_linux-x64_bin.tar.gz

systemctl daemon-reload
systemctl start jenkins