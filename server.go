package main

import (
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/playground"
	"github.com/jkzilla/egg/graph"
	"github.com/jkzilla/egg/graph/model"
	"github.com/rs/cors"
)

const defaultPort = "8080"

// corsMiddleware adds CORS headers to allow frontend access
func corsMiddleware(next http.Handler) http.Handler {
	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	})
	return c.Handler(next)
}

// spaHandler implements the http.Handler interface for serving a SPA
type spaHandler struct {
	staticPath string
	indexPath  string
}

func (h spaHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	path := filepath.Join(h.staticPath, r.URL.Path)
	
	// Check if file exists
	_, err := os.Stat(path)
	if os.IsNotExist(err) {
		// File does not exist, serve index.html
		http.ServeFile(w, r, filepath.Join(h.staticPath, h.indexPath))
		return
	} else if err != nil {
		// Other error
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	// File exists, serve it
	http.FileServer(http.Dir(h.staticPath)).ServeHTTP(w, r)
}

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

	// GraphQL endpoints
	http.Handle("/graphql", corsMiddleware(srv))
	http.Handle("/playground", playground.Handler("GraphQL playground", "/graphql"))

	// Serve static files from frontend/dist
	spa := spaHandler{staticPath: "frontend/dist", indexPath: "index.html"}
	http.Handle("/", spa)

	log.Printf("Server starting on http://localhost:%s", port)
	log.Printf("GraphQL playground: http://localhost:%s/playground", port)
	log.Printf("Frontend: http://localhost:%s/", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func strPtr(s string) *string {
	return &s
}
