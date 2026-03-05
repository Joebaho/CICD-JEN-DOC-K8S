#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release unzip git wget apt-transport-https software-properties-common

# Install Docker
apt-get install -y docker.io
systemctl enable --now docker
usermod -aG docker ubuntu || true

# Install AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# Install kubectl
curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# Install Jenkins (LTS) + Java runtime
mkdir -p /usr/share/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -y
if apt-cache show openjdk-21-jre >/dev/null 2>&1; then
  apt-get install -y fontconfig openjdk-21-jre jenkins
else
  echo "openjdk-21-jre not available on this image, falling back to openjdk-17-jre"
  apt-get install -y fontconfig openjdk-17-jre jenkins
fi

# Disable setup wizard for automated bootstrap
mkdir -p /etc/systemd/system/jenkins.service.d
cat >/etc/systemd/system/jenkins.service.d/override.conf <<EOT
[Service]
Environment="JAVA_OPTS=-Djenkins.install.runSetupWizard=false"
EOT

systemctl daemon-reload
systemctl enable --now jenkins

# Install required Jenkins plugins
jenkins-plugin-cli --plugins \
  git \
  workflow-aggregator \
  docker-workflow \
  credentials-binding \
  pipeline-aws

systemctl restart jenkins

# Add jenkins user to docker group after installation
usermod -aG docker jenkins || true
systemctl restart docker
systemctl restart jenkins
