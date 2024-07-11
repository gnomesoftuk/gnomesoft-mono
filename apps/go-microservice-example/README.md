# go-microservice

A very simple microservice to demonstrate how to run go applications in a container
and deploy them.

## Development

To build the container run:
`docker buildx build -t <org>/go-microservice .`

## Architecture

The microservice image uses a two stage build, with the final image based on
a distroless base. This makes the image absolutely tiny, about ~13MB.

This works because of Go's ability to statically compile all it's dependencies
into one binary file.

https://blog.baeke.info/2021/03/28/distroless-or-scratch-for-go-apps/

Having a small image is great for security as the attack-surface is small,
it reduces deployment times and network I/O.

To make this more secure, we must copy the base images we're using
to our own private repository, and verify them before use.

https://snyk.io/blog/signing-container-images/