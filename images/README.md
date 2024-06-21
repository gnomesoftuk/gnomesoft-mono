# images

## usage

```
export DOCKER_PASS=<token>
make IMAGE=<image>
```

If your container has an open port then use

```
export DOCKER_PASS=<token>
make with_test IMAGE=<image>
```