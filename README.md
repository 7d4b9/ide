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

## Bootstrap

Creates an instance, waits ssh to be available, then prepare the instance or restore an image if `dist/image.tar` exists.

```sh
make bootstrap
```

same that

```sh
make create wait-ssh install prepare
```

## Start vpn

After `bootsrap` success it is possible to remotely start the distant vpn client service if *VPN* is set.

```sh
make start vpn
```

## Connect to the distant instance with ssh

```sh
make ssh
```

## Update

Creates an image of the running distant instance, then destroys, recreates and restores the image of the old instance on the new one.

```sh
make update
```

same that:

```sh
make image destroy create
```

## Save and quit

```sh
make save-quit
```

same that:

```sh
make image destroy
```

Saves a local `dist/image.tar` based on SAVING (cf [Makefile](Makefile)),
then destroy the infrastructure.

## Clone a project

Following step requires validates:

* *VPN* connection
* *SSH* credentials

```sh
git clone custom@project.git
```