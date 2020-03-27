# IDE

Required:

* AWS account
* SSH

## Create

```sh
make bootstrap
```

>### output_instance_ip = 34.xx.xxx.129

```sh
make recreate
```

## Destroy

```sh
make image destroy
```

Creates a local ìmage `dist/image.tar`, then destroy infrastructure.

The image is used by `make recreate`.

## SSH

```sh
make ssh
```

## Update

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
