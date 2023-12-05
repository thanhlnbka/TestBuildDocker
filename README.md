# Build image arm64 on adm64
```bash
sudo apt-get install qemu qemu-user-static
export DOCKER_CLI_AARCH64=1
docker buildx create --use
docker buildx build --platform linux/arm64 -t your-image-name:tag .
```


# Run image arm64 on adm64 
```bash
sudo apt-get install qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker run --rm -it --network host your-image-name:tag
```
