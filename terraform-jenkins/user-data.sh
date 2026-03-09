#!/bin/bash

set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Persist cloud-init output for troubleshooting.
exec > >(tee /var/log/jenkins-user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "==========Updating system...=========="
apt update -y
apt upgrade -y

echo "==========Installing base packages...=========="
apt install -y curl wget git unzip zip ca-certificates gnupg lsb-release

echo "==========Installing Java...=========="
apt install -y openjdk-21-jdk

echo "==========Installing Jenkins...=========="

curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2026.key \
| tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" \
| tee /etc/apt/sources.list.d/jenkins.list

apt update -y
apt install -y jenkins

systemctl enable jenkins
systemctl start jenkins

echo "==========Installing Docker...=========="

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| gpg --dearmor -o /usr/share/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| tee /etc/apt/sources.list.d/docker.list

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io

systemctl enable docker
systemctl start docker
groupadd -f docker
usermod -aG docker ubuntu || true
usermod -aG docker jenkins || true

echo "==========Installing kubectl...=========="

curl -LO https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

echo "==========Installing eksctl...=========="

curl -sLO https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz
tar -xzf eksctl_Linux_amd64.tar.gz
mv eksctl /usr/local/bin
rm eksctl_Linux_amd64.tar.gz

echo "==========Installing Terraform...=========="

curl -fsSL https://apt.releases.hashicorp.com/gpg \
| gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
| tee /etc/apt/sources.list.d/hashicorp.list

apt update -y
apt install -y terraform

echo "==========Installing AWS CLI...=========="
apt install -y awscli

echo "========== VERIFY INSTALLATIONS =========="

echo "Jenkins:"
systemctl status jenkins --no-pager

echo "Docker:"
docker --version

echo "Kubectl:"
kubectl version --client

echo "AWS CLI:"
aws --version

echo "Terraform:"
terraform -version

echo "Eksctl:"
eksctl version

echo "========== INSTALLATION COMPLETE =========="

PUBLIC_IP=$(curl -s checkip.amazonaws.com)

echo "Access Jenkins at:"
echo "http://$PUBLIC_IP:8080"

echo "Jenkins initial password:"
cat /var/lib/jenkins/secrets/initialAdminPassword

