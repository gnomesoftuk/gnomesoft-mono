FROM golang:1.22.4

WORKDIR /usr/src/app

COPY go.mod go.sum ./

# cache go dependencies
RUN go mod download && go mod verify

COPY . .

RUN go build -v -o /usr/local/bin/app ./cmd/web/main.go

EXPOSE 8080

CMD [ "app" ]