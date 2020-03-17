# IDE

Required:

* AWS account
* SSH

## Create

Create an instance with a *public IP* `IP-Address` based on [providers.tf](providers.tf)

```sh
make create
# output IP_ADDR_PUBLIC=34.xx.xxx.129
```

## IP Addr

```sh
export ADDR=34.xx.xxx.129
```

## Build

Creates an instance, waits ssh to be available, then prepare the instance or restore an image if `dist/image.tar` exists.

### Bootstrap

```sh
make bootstrap
```

### Rebuild

After calling `make bootstrap` the very first time, call `make rebuild` to recreate
the stack from scratch.
This is required if a current running instance holds a mounted cloud resource to relase the resource,
thus allowing successful destruction and re-bootstrap.

```sh
make rebuild
```

## Connect to the distant instance with ssh

```sh
make ssh
```

## Update

Creates an image of the running distant instance, then destroys, recreates and restores the image of the old instance on the new one.

```sh
make upgrade
```

same that:

```sh
make image destroy bootstrap
```

## Save and quit

```sh
make image destroy
```

Saves a local `dist/image.tar` based on [SAVING](Makefile), then destroy the infrastructure.

## Clone a project

Following step requires validates:

* *VPN* connection
* *SSH* credentials

```sh
git clone custom@project.git
```