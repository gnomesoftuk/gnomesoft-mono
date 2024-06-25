# images

## status

[![CircleCI](https://dl.circleci.com/status-badge/img/circleci/H5y8pSbtKW5zEhJYp5MwQz/SxRiaWWoLk2d6W6NB9dEGR/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/circleci/H5y8pSbtKW5zEhJYp5MwQz/SxRiaWWoLk2d6W6NB9dEGR/tree/main)

## usage

```
export DOCKER_PASS=<token>
export DOCKER_BUILD_ARGS='--build-arg="ARCH=[amd64|arm64]"' (optional)
make IMAGE=<image>
```

If your container has an open port then use

```
export DOCKER_PASS=<token>
export DOCKER_BUILD_ARGS='--build-arg="ARCH=[amd64|arm64]"' (optional)
make with_test IMAGE=<image>
```