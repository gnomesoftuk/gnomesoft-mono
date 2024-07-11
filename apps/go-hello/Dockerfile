ARG GO_VERSION=1.22.4

# BUILD STAGE
FROM golang:${GO_VERSION}-alpine AS build

RUN apk add --no-cache git
RUN apk --no-cache add ca-certificates
 
# add a user here because addgroup and adduser are not available in scratch
RUN addgroup -S app \
    && adduser -S -u 10000 -g app app

WORKDIR /src

COPY go.mod go.sum ./

# cache go dependencies
RUN go mod download && go mod verify

COPY /. ./

# Run tests (disabled as I don't have any yet)
# RUN CGO_ENABLED=0 go test -timeout 30s

# Build executable
RUN CGO_ENABLED=0 go build \
    -installsuffix 'static' \
    -o /app ./cmd/web

#RUN go build -v -o /usr/local/bin/app ./cmd/web/main.go

# RUN STAGE
FROM gcr.io/distroless/static AS run

LABEL maintainers=gnomesoftuk
USER nonroot:nonroot

# Copy app binary
COPY --from=build /app /app

EXPOSE 8080

CMD [ "/app" ]