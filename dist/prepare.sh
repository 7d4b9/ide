#!/bin/bash

echo export PATH=\$PATH:/usr/local/go/bin >> /etc/profile
echo export GOSUMDB=off >> /etc/profile
mkfs -t xfs /dev/xvdh
echo /dev/xvdh	/var/lib/docker	xfs	defaults,nofail	0	2 >> /etc/fstab
systemctl stop docker
mount /dev/xvdh
systemctl start docker