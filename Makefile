DIST_USER := ubuntu

ifndef ADDR
ADDR := ide
endif

DIST = $(DIST_USER)@$(ADDR)

ssh:
	@ssh $(DIST)
.PHONY: ssh

BACKUP = ide-backup.tar

pull-backup: save
	@-scp $(DIST):/home/$(DIST_USER)/$(BACKUP) $(BACKUP)
.PHONY: pull-backup

push-backup:
	@scp $(BACKUP) $(DIST):/home/$(DIST_USER)/$(BACKUP)
.PHONY: push-backup

create: terraform
	@terraform apply
.PHONY: create

prepare:
	@scp dist/install.sh $(DIST):/home/$(DIST_USER)
	@scp dist/backup.sh $(DIST):/home/$(DIST_USER)
.PHONY: prepare

dist/vpn.user:
	@read -p 'vpn-user: ' user && echo $$user > $@
	@read -sp 'vpn-user-password: ' password && echo $$password >> $@

dist-vpn-user: dist/vpn.user
	@scp dist/vpn.user $(DIST):/home/$(DIST_USER)
	@ssh $(DIST) sudo mv vpn.user /etc/openvpn/client/
.PHONY: dist-vpn-user

push-vpn-conf: dist-vpn-user
	@scp dist/client.ovpn $(DIST):/home/$(DIST_USER)/client.ovpn
	@ssh $(DIST) sudo mv client.ovpn /etc/openvpn/client/client.conf
.PHONY: push-vpn-conf

pull-ssh-cred:
	@scp $(DIST):/home/$(DIST_USER)/.ssh/id_rsa dist/id_rsa
	@scp $(DIST):/home/$(DIST_USER)/.ssh/id_rsa.pub dist/id_rsa.pub
.PHONY: pull-ssh-cred

push-ssh-cred:
	@scp dist/id_rsa $(DIST):/home/$(DIST_USER)/.ssh/id_rsa
	@scp dist/id_rsa.pub $(DIST):/home/$(DIST_USER)/.ssh/id_rsa.pub
.PHONY: push-ssh-cred

pull-git-config:
	@scp $(DIST):/home/$(DIST_USER)/.gitconfig dist/gitconfig
.PHONY: pull-git-config

push-git-config:
	@scp dist/gitconfig $(DIST):/home/$(DIST_USER)/.gitconfig
.PHONY: push-git-config

save:
	@ssh  $(DIST) ./backup.sh
.PHONY: save

install:
	@ssh  $(DIST) sudo ./install.sh
.PHONY: install

start-vpn stop-vpn:
	@ssh  $(DIST) sudo systemctl $(@:%-vpn=%) openvpn-client@client
.PHONY: start-vpn stop-vpn

destroy: terraform pull-backup
	@terraform destroy
.PHONY: destroy

terraform: .terraform
.PHONY: terraform

.terraform:
	@terraform init