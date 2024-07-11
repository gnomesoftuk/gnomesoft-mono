package main

import (
	"gnomesoftuk/gohello/internal/server"
)

func main() {
	m := server.HttpServer{}
	m.InitHttpServer()
}
