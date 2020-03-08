#!/bin/sh

ARCHIVE=ide-backup.tar

rm -f $HOME/*-backup.*

docker rm -f `docker ps -aq` 2>/dev/null
docker rmi -f `docker images -aq` 2>/dev/null

tar cvaf /tmp/$ARCHIVE \
	/etc/openvpn/client/client.ovpn \
	/etc/openvpn/client/vpn.user \
	/etc/resolv.conf \
	/etc/profile \
	/etc/bash.bashrc \
	/usr/local/bin \
	/usr/local/go \
	$HOME/.ssh \
	$HOME/.gitconfig \
	$HOME/bin \
	$HOME/go

mv /tmp/$ARCHIVE $HOME