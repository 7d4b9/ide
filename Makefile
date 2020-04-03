SHELL := bash

TERRAFORM_VERSION := 0.12.23
TERRAFORM := ./terraform

ifndef ADDR
ADDR = `$(TERRAFORM) output instance_ip_addr`
endif

DIST_USER := ubuntu
DIST = $(DIST_USER)@$(ADDR)

export

# use recreate to re-bootstrap (requiring volume release...)
bootstrap: .bootstrap.done
.PHONY: bootstrap

.bootstrap.done:
	@$(MAKE) create init-ssh install prepare
	@-ssh $(DIST) sudo reboot
	@echo Reboot system...please wait.
	@while ! nc -z "$(ADDR)" 22 ; do sleep 1 ; done
	@echo System is up.
	@touch $@

recreate: release
	@-rm .bootstrap.done 2> /dev/null
	@$(MAKE) bootstrap
.PHONY: recreate

ssh:
	@ssh $(DIST)
.PHONY: ssh

upgrade: image recreate
.PHONY: upgrade

create: .terraform deployer-pub-key
	@$(TERRAFORM) apply
.PHONY: create

deployer-pub-key: dist/id_rsa.pub

dist/%: $(HOME)/.ssh/%
	@echo Will make use of user SSH $<
	@cp $< $@

dist/gitconfig: $(HOME)/.gitconfig
	@echo Will make use of user gitconfig $<
	cp $< $@

dist/vpn.user:
	@read -p 'vpn-user: ' user && echo $$user > $@
	@read -sp 'vpn-user-password: ' password && echo $$password >> $@

SAVING = \
	/home \
	/etc/openvpn/client/$(VPN_CONF).conf \
	/etc/openvpn/client/vpn.user \
	/etc/hosts \
	/etc/default/openvpn \
	/etc/fstab \
	/etc/profile

ifndef IMAGE
IMAGE = dist/image.tar
endif

image: $(IMAGE)
.PHONY: image

ifneq (,$(wildcard $(IMAGE)))
prepare:
	@echo Restoring files from $(IMAGE)...
	@cat $(IMAGE) | ssh $(DIST) sudo tar -xC /
	@echo Files restored from $(IMAGE).
.PHONY: prepare
else
prepare: push-config
	@cat ./dist/prepare.sh | ssh $(DIST) sudo su
.PHONY: prepare
endif

$(IMAGE:%image.tar=%_image.tar):
	@echo Saving image $(IMAGE)...
	@ssh $(DIST) tar cf - $(SAVING) 2>/dev/null | cat > $@
	@echo Saved image $(IMAGE)

$(IMAGE): $(IMAGE:dist/%=dist/_%)
	@-for i in `ls $@* 2>/dev/null` ; do mv $$i $${i}_ ; done
	@mv $< $(IMAGE)
ifneq (,$(VPN_CONF))
push-vpn-user-cred: dist/vpn.user
	@scp dist/vpn.user $(DIST):/home/$(DIST_USER)
.PHONY: push-vpn-user-cred
push-vpn-%-file: dist/%.ovpn
	@scp dist/$*.ovpn $(DIST):/home/$(DIST_USER)/$*.ovpn
push-vpn-%-conf: push-vpn-%-file push-vpn-user-cred
	@ssh $(DIST) sudo mv /home/$(DIST_USER)/vpn.user /etc/openvpn/client/
	@ssh $(DIST) sudo mv /home/$(DIST_USER)/$*.ovpn /etc/openvpn/client/$*.conf
start-vpn-%: push-vpn-%-conf
	@echo Enable VPN for $*
	@ssh $(DIST) sudo systemctl enable openvpn-client@$*
	@ssh $(DIST) sudo systemctl start openvpn-client@$*
	@echo Enabled VPN for $*
endif

pull-ssh-cred:
	@echo Pulling ssh credential from $(DIST) to host
	@scp $(DIST):/home/$(DIST_USER)/.ssh/id_rsa dist/id_rsa
	@scp $(DIST):/home/$(DIST_USER)/.ssh/id_rsa.pub dist/id_rsa.pub
.PHONY: pull-ssh-cred

push-ssh-cred: dist/id_rsa dist/id_rsa.pub
	@echo Pushing ssh credential to $(DIST) from host
	@scp dist/id_rsa $(DIST):/home/$(DIST_USER)/.ssh/id_rsa
	@scp dist/id_rsa.pub $(DIST):/home/$(DIST_USER)/.ssh/id_rsa.pub
.PHONY: push-ssh-cred

pull-git-config:
	@echo Pulling gitconfig from $(DIST) to host
	@scp $(DIST):/home/$(DIST_USER)/.gitconfig dist/gitconfig
.PHONY: pull-git-config

push-git-config: dist/gitconfig
	@echo Pushing initial gitconfig from host to $(DIST)
	@scp dist/gitconfig $(DIST):/home/$(DIST_USER)/.gitconfig
.PHONY: push-git-config

push-config: push-git-config push-ssh-cred
	@echo Pushed SSH configuration
.PHONY: push-config

install:
	@cat ./dist/install.sh | ssh $(DIST) sudo su
	@-ssh $(DIST) sudo mkfs -t xfs /dev/xvdh 2>/dev/null
.PHONY: install

release:
	@#Prevent aws resource busy at destroy (cannot detach ebs)
	@-ssh $(DIST) sudo systemctl stop docker
	@-ssh $(DIST) sudo umount /var/lib/docker
.PHONY: release

destroy: release .terraform
	@$(TERRAFORM) destroy
	@-ssh-keygen -R $(ADDR) 2>/dev/null
.PHONY: destroy

init-ssh:
	@while ! nc -z "$(ADDR)" 22 ; do echo Waiting SSH at $(ADDR)... ; sleep 1 ; done ;
	@echo Removing $(ADDR) from SSH known hosts
	@ssh-keygen -R $(ADDR)
.PHONY: init-ssh

.terraform: terraform
	@$(TERRAFORM) init

ifeq ($(OS),Windows_NT)
  ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
    TERRAFORM_ARCHIVE = terraform_$(TERRAFORM_VERSION)_windows_amd64.zip
  else
    ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
      TERRAFORM_ARCHIVE = terraform_$(TERRAFORM_VERSION)_windows_amd64.zip
    endif
    ifeq ($(PROCESSOR_ARCHITECTURE),x86)
      TERRAFORM_ARCHIVE = terraform_$(TERRAFORM_VERSION)_windows_386.zip
    endif
  endif
else
  UNAME_S := $(shell uname -s)
  ifeq ($(UNAME_S),Linux)
    UNAME_P := $(shell uname -p)
    ifeq ($(UNAME_P),x86_64)
      TERRAFORM_ARCHIVE = terraform_$(TERRAFORM_VERSION)_linux_amd64.zip
    endif
    ifneq ($(filter %86,$(UNAME_P)),)
      TERRAFORM_ARCHIVE = terraform_$(TERRAFORM_VERSION)_linux_386.zip
    endif
    ifneq ($(filter arm%,$(UNAME_P)),)
      TERRAFORM_ARCHIVE = terraform_$(TERRAFORM_VERSION)_linux_arm.zip
    endif
  endif
  ifeq ($(UNAME_S),Darwin)
    TERRAFORM_ARCHIVE = terraform_$(TERRAFORM_VERSION)_darwin_amd64.zip
  endif
endif

$(TERRAFORM_ARCHIVE):
	@echo downloading $@
	@curl -O https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/$@

terraform: $(TERRAFORM_ARCHIVE)
	@echo extracting $@...
	@unzip $< && touch $@

AUTOMATIC_TARGETS := bootstrap recreate upgrade shutdown destroy

$(AUTOMATIC_TARGETS:%=auto-%):
	@./auto.sh $(@:auto-%=%)
.PHONY: $(AUTOMATIC_TARGETS:%=auto-%)
