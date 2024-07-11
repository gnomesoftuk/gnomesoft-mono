package server

import (
	"net/http"
	"runtime"

	"github.com/gin-gonic/gin"
)

type HttpServer struct {
	router *gin.Engine
}

func (m *HttpServer) InitHttpServer() {
	m.router = gin.Default()
	m.router.GET("/hello", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Hello World!",
		})
	})

	m.router.GET("/os", func(c *gin.Context) {
		c.String(http.StatusOK, runtime.GOOS)
	})

	m.router.GET("/healthz", func(c *gin.Context) {
		c.String(http.StatusOK, "OK")
	})

	m.router.Run(":8080")
}
