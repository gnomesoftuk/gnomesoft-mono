package main

import (
	"gnomesoftuk/gomicroservice/internal/server"
)

func main() {
	m := server.HttpServer{}
	m.InitHttpServer()
}
