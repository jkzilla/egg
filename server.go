package main

import (
	"log"
	"net/http"
	"os"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/playground"
	"github.com/jkzilla/egg/graph"
	"github.com/jkzilla/egg/graph/model"
)

const defaultPort = "8080"

// startServer runs the GraphQL API server
func startServer() {
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	// Create resolver with sample data
	resolver := graph.NewResolver()

	// Add sample eggs
	resolver.AddEgg(&model.Egg{
		ID:                "1",
		Type:              "Brown Chicken Egg",
		Price:             0.50,
		QuantityAvailable: 24,
		Description:       strPtr("Fresh brown eggs from free-range chickens"),
	})
	resolver.AddEgg(&model.Egg{
		ID:                "2",
		Type:              "White Chicken Egg",
		Price:             0.45,
		QuantityAvailable: 36,
		Description:       strPtr("Fresh white eggs from cage-free hens"),
	})
	resolver.AddEgg(&model.Egg{
		ID:                "3",
		Type:              "Duck Egg",
		Price:             1.25,
		QuantityAvailable: 12,
		Description:       strPtr("Large duck eggs, perfect for baking"),
	})
	resolver.AddEgg(&model.Egg{
		ID:                "4",
		Type:              "Quail Egg",
		Price:             0.75,
		QuantityAvailable: 48,
		Description:       strPtr("Delicate quail eggs, great for appetizers"),
	})

	srv := handler.NewDefaultServer(graph.NewExecutableSchema(graph.Config{Resolvers: resolver}))

	http.Handle("/", playground.Handler("GraphQL playground", "/query"))
	http.Handle("/query", srv)

	log.Printf("Connect to http://localhost:%s/ for GraphQL playground", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func strPtr(s string) *string {
	return &s
}
