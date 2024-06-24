# images

## usage

```
export DOCKER_PASS=<token>
export DOCKER_BUILD_ARGS='--build-arg="ARCH=[amd64|arm64]"'
make IMAGE=<image>
```

If your container has an open port then use

```
export DOCKER_PASS=<token>
export DOCKER_BUILD_ARGS='--build-arg="ARCH=[amd64|arm64]"'
make with_test IMAGE=<image>
```