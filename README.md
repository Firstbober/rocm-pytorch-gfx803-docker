# rocm-pytorch-gfx803-docker
A Docker image based on rocm/pytorch with support for gfx803(Polaris 20-21 (XT/PRO/XL); RX580; RX570; RX560) and Python 3.8  

For ROCM 5.4.1

After creating container, you will be logged as `root` with activated python3.8 environment.

This is a rootless version, which means that your podman/docker needs to be run as rootless
and with the files you write within mounted volume as root inside container, on the host will have user ownership and permission.

Supports docker and podman rootless

torch, torchvision and tensorflow-rocm packages are downloaded from https://github.com/xuhuisheng/rocm-gfx803

Every downloaded package should be in `/packages`.

## Building image
```
podman build -t rocm-pytorch-gfx803 ./rocm-pytorch-gfx803-docker
```

## Creating container
```
podman run -it --device=/dev/kfd --device=/dev/dri --net=host localhost/rocm-pytorch-gfx803
```

Not required, but recommended is `-v /host:/container` parameter. It is easier to work when you have easy access to files already in your system. `/host` can be any path on host and `/container` any path on container.
