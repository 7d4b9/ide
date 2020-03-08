#!/bin/sh

apt-get update && apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  git \
  gnupg-agent \
  make \
  openvpn \
  openvpn-systemd-resolved \
  software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker $USER
curl -L https://dl.google.com/go/go1.14.linux-amd64.tar.gz | tar -xz -C /usr/local
cat <<'EOF' >> /etc/profile
export PATH=$PATH:/usr/local/go/bin
EOF