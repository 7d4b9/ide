#!/bin/sh

apt-get update && apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  git \
  gcc \
  gnupg-agent \
  make \
  openvpn \
  openvpn-systemd-resolved \
  software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
usermod -aG docker ubuntu
newgrp docker
curl -L https://dl.google.com/go/go1.14.linux-amd64.tar.gz | tar -xz -C /usr/local
mkfs -t xfs /dev/xvdh 2>/dev/null
