#!/bin/bash

R="\e[31m"
G="\e[32m"
N="\e[0m"

echo -e "$G Starting DevOps workstation setup $N"

# System Update
sudo yum update -y

# Installing Docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo \
  https://download.docker.com/linux/rhel/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
echo -e "$G Docker installed $N"

# Installing kubectl
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
echo -e "$G kubectl installed $N"

# Installing Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
echo -e "$G Minikube installed $N"

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh
echo -e "$G Helm installed $N"

# Install kubens + kubectx
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
echo -e "$G kubens and kubectx installed $N"

# Install Git
sudo yum install -y git
git config --global user.name "Sai Venkata Siva Mutyala"
git config --global user.email "msaivenkatasiva@gmail.com"
echo -e "$G Git installed $N"

# Install Python3 + pip
sudo yum install -y python3 python3-pip
echo -e "$G Python installed $N"

# Extend Volume (dynamic)
ROOT_DISK=$(lsblk -d -o NAME | grep -E 'nvme0n1|xvda' | head -1)
PART_NUM=$(lsblk -no PARTNUM /dev/${ROOT_DISK}p* 2>/dev/null | tail -1)
echo -e "$G Root disk: $ROOT_DISK, Partition: $PART_NUM $N"

if sudo lvdisplay &>/dev/null; then
  sudo growpart /dev/$ROOT_DISK $PART_NUM || true
  sudo lvextend -l +50%FREE /dev/RootVG/rootVol || true
  sudo lvextend -l +50%FREE /dev/RootVG/varVol || true
  sudo xfs_growfs / || true
  sudo xfs_growfs /var || true
  echo -e "$G Volume extended $N"
fi

# running a small verification for better clarity
echo -e "$G All tools installed! $N"
echo -e "$G Versions: $N"
docker --version
kubectl version --client
minikube version
helm version --short
git --version
python3 --version
echo -e "$R IMPORTANT: Logout and login $N"
echo -e "$R again for Docker group to $N"
echo -e "$R take effect before starting $N"
echo -e "$R Minikube! $N"