package routes

import (
	"app/webserver/controllers"
	"app/webserver/graphql"
	"github.com/gin-gonic/gin"
)

// Init routes.
func InitAPI(app *gin.RouterGroup) {
	app.GET("/health", controllers.HealthHandler)
	app.GET("/db_health", controllers.HealthDBHandler)
	app.GET("/samples", controllers.ListHandler)
	app.GET("/hosts/:id", controllers.GetHostHandler)
	app.GET("/create", controllers.CreateHandler)
	app.GET("/delete", controllers.DeleteHandler)
	app.GET("/graphql", graphql.Handler)
}

func InitGraphQLPlayground(app *gin.RouterGroup) {
	app.GET("/playground", graphql.PlaygroundHandler)
	app.POST("/playground", graphql.PlaygroundHandler)
}
