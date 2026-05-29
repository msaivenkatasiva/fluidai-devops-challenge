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

# Installing AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo yum install -y unzip
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/
echo -e "$G AWS CLI installed $N"

# Installing eksctl
curl --silent --location \
  "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
  | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
echo -e "$G eksctl installed $N"

# Installing kubectl
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
echo -e "$G kubectl installed $N"

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
aws --version
eksctl version
kubectl version --client
helm version --short
git --version
python3 --version
echo -e "$R IMPORTANT: Logout and login $N"
echo -e "$R again for Docker group to $N"
echo -e "$R take effect! $N"