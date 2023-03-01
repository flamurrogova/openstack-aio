#!/usr/bin/env bash

# install docker per the k8s docs - run this script as user

set -e
set -u
set -o pipefail


#echo -n "\n\nconfigure apt-cacher\n" && echo "Acquire::http::Proxy \"http://192.168.1.226:3142\";" | sudo tee /etc/apt/apt.conf.d/00aptproxy
#echo -n "\n\nconfigure apt-cacher\n" && echo "Acquire::http::Proxy \"http://10.10.10.17:3142\";" | sudo tee /etc/apt/apt.conf.d/00aptproxy

sudo apt update
#sudo apt-get remove docker-ce docker.io containerd runc

# 1. Update the apt package index and install packages to allow apt to use a repository over HTTPS:
sudo apt-get install --yes ca-certificates curl gnupg lsb-release

# 2. Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg


# 3. Use the following command to set up the stable repository.
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


sudo apt-get update
sudo apt-get install --yes docker-ce docker-ce-cli containerd.io

#sudo mkdir /etc/docker

# Set up the Docker daemon
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "storage-driver": "overlay2"
}
EOF


#sudo mkdir -p /etc/systemd/system/docker.service.d


sudo systemctl daemon-reload
sudo systemctl restart docker

sudo systemctl enable docker

sudo usermod -aG docker $USER

