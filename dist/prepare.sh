#!/bin/bash

echo export PATH=\$PATH:/usr/local/go/bin >> /etc/profile
echo export GOSUMDB=off >> /etc/profile
echo /dev/xvdh	/var/lib/docker	xfs	defaults,nofail	0	2 >> /etc/fstab
sed -i s/\#AUTOSTART=\"all\"/AUTOSTART=\"all\"/ /etc/default/openvpn
systemctl daemon-reload
