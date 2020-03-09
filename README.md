# IDE

Required:
* AWS account
* Terraform
* SSH


## Create machine

Create instance with a *public IP* `IP-Address`

```sh
make create
# output IP_ADDR_PUBLIC=34.xx.xxx.129
```

## Export new Addr

```sh
export ADDR=34.xx.xxx.129
```
Or simply append the line bellow to your local `/etc/hosts`

> `34.xx.xxx.129 ide`

this will automatically satisfy the [Makefile](Makefile#L4) default `ADDR = ide`.

## Update remote environment

```sh
make prepare install push-vpn-conf start-vpn push-git-config push-ssh-cred
```

## Connect to remote environement by using ssh

```sh
make ssh
```

## Clone a project

Following step requires validates:
* *VPN* connection
* *SSH* credentials

```sh
git clone custom@project.git
```