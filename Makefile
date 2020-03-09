SHELL := bash

ifndef ADDR
ADDR := `terraform output instance_ip_addr`
ifeq (, $(ADDR))
ADDR := localhost
endif
endif

DIST_USER := ubuntu
DIST = $(DIST_USER)@$(ADDR)

export

ssh:
	@ssh $(DIST)
.PHONY: ssh

create: terraform
	@terraform apply
.PHONY: create

dist-ssh-key: dist/id_rsa dist/id_rsa.pub

dist/%: $(HOME)/.ssh/%
	@echo "Will make use of user SSH $@"
	@cp $< $@

dist/gitconfig: $(HOME)/.gitconfig
	@echo "Will make use of user gitconfig $<"
	cp $< $@

dist/vpn.user:
	@read -p 'vpn-user: ' user && echo $$user > $@
	@read -sp 'vpn-user-password: ' password && echo $$password >> $@

SAVING = \
	/home/$(DIST_USER)/.bash_history \
	/home/$(DIST_USER)/.bashrc \
	/home/$(DIST_USER)/.gitconfig \
	/home/$(DIST_USER)/workspace \
	/home/$(DIST_USER)/.profile \
	/home/$(DIST_USER)/.ssh/id_rsa \
	/home/$(DIST_USER)/.ssh/id_rsa.pub \
	/home/$(DIST_USER)/.ssh/known_hosts \
	/etc/openvpn/client/client.conf \
	/etc/openvpn/client/vpn.user \
	/etc/hosts \
	/etc/fstab \
	/etc/profile

ifndef IMAGE
IMAGE = dist/image.tar
endif

image: $(IMAGE)
.PHONY: image

ifneq (,$(wildcard $(IMAGE)))
prepare:
	@echo "restoring..."
	@cat $(IMAGE) | ssh $(DIST) sudo tar -xC /
else

define ENVIRON
export PATH=$$PATH:/usr/local/go/bin
export GOSUMDB=off
endef

export ENVIRON

prepare: push-config
	@echo "$$ENVIRON" | ssh $(DIST) sudo tee -a /etc/profile
	@ssh $(DIST) sudo cat /etc/profile
endif

.PHONY: prepare

update: image destroy create
.PHONY: update

$(IMAGE:%image.tar=%_image.tar):
	@echo Saving image $'$(@:%_image.tar=%image.tar)$'...
	@ssh $(DIST) tar cvf - $(SAVING) 2>/dev/null | cat > $@
	@echo Saved image $'$(@:%_image.tar=%image.tar)$'

$(IMAGE): $(IMAGE:dist/%=dist/_%)
	@-for i in `ls $@* 2>/dev/null` ; do mv $$i $${i}_ ; done
	@mv $< $(IMAGE)

push-vpn-user: dist/vpn.user
	@scp dist/vpn.user $(DIST):/home/$(DIST_USER)
.PHONY: push-vpn-user

push-vpn: push-vpn-conf push-vpn-user
	@ssh $(DIST) sudo mv /home/$(DIST_USER)/vpn.user /etc/openvpn/client/
	@ssh $(DIST) sudo mv /home/$(DIST_USER)/client.ovpn /etc/openvpn/client/client.conf
.PHONY: push-vpn

push-vpn-conf: dist/client.ovpn
	@scp dist/client.ovpn $(DIST):/home/$(DIST_USER)/client.ovpn
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

push-git-config: dist/gitconfig
	@scp dist/gitconfig $(DIST):/home/$(DIST_USER)/.gitconfig
.PHONY: push-git-config

push-config: push-git-config push-ssh-cred push-vpn

install:
	@cat ./dist/install.sh | ssh $(DIST) sudo su
.PHONY: install

start-vpn:
	@ssh  $(DIST) sudo systemctl $(@:%-vpn=%) openvpn-client@client
.PHONY: start-vpn

destroy: terraform
	@terraform destroy
	@-ssh-keygen -R "$(ADDR)"
.PHONY: destroy

terraform: .terraform dist-ssh-key
.PHONY: terraform

.terraform:
	@terraform init

setup:
	@while ! nc -z $(ADDR) 22 ; do echo "Waiting SSH at $(ADDR)..." ; sleep 1 ; done ; \
	ssh-keygen -R $(ADDR) ; \
	$(MAKE) install prepare start-vpn ; \
	echo $@ created instance at $(ADDR) ;
.PHONY: setup

bootstrap: create setup
.PHONY: bootstrap

save-quit: image destroy
.PHONY: save-quit
